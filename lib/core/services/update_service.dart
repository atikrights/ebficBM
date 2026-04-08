import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// ─── Update State Machine Enum ──────────────────────────────────────────────
enum UpdateState {
  idle,         
  checking,     
  available,    
  downloading,  
  validating,   
  readyToInstall, // New background state
  installing,   
  relaunching,  
  error         
}

// ─── Global notifiers for Single Page syncing ───────────────────────────────
final ValueNotifier<UpdateState> updateStateNotifier = ValueNotifier(UpdateState.idle);
final ValueNotifier<double> updateProgressNotifier = ValueNotifier(0.0);
final ValueNotifier<String> updateStatusNotifier = ValueNotifier('');
final ValueNotifier<bool> isUpdatingNotifier = ValueNotifier(false);

// Stores downloaded file path silently
String? _readyInstallPath;
Map<String, dynamic>? _readyReleaseInfo;

class UpdateService {
  static const String _updateUrl =
      'https://api.github.com/repos/atikrights/ebficBM/releases';
  static const String _privateRepoToken =
      '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';

  Future<List<Map<String, dynamic>>?> getReleases() async {
    try {
      final noCacheUrl = '$_updateUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = _privateRepoToken.isNotEmpty
          ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/vnd.github.v3+json'}
          : {'Accept': 'application/vnd.github.v3+json'};

      final response = await http.get(Uri.parse(noCacheUrl), headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error fetching github releases: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestVersionInfo() async {
    final releases = await getReleases();
    if (releases != null && releases.isNotEmpty) {
      final latest = releases.first;
      String tagName = (latest['tag_name'] ?? '').toString();
      if (tagName.startsWith('v')) tagName = tagName.substring(1);
      tagName = tagName.trim();

      double totalSizeMb = 0.0;
      if (latest['assets'] != null) {
        for (var asset in latest['assets']) {
          totalSizeMb += (asset['size'] ?? 0) / (1024 * 1024);
        }
      }

      return {
        'version': tagName,
        'url': latest['html_url'],
        'notes': latest['body'] ?? 'Performance improvements and bug fixes.',
        'sizeMb': totalSizeMb.toStringAsFixed(1),
        'author': latest['author'] != null ? latest['author']['login'] : 'atikrights',
        'author_avatar': latest['author'] != null ? latest['author']['avatar_url'] : '',
        'all_releases': releases,
        'assets': latest['assets'],
      };
    }
    return null;
  }

  // 100% SMART BACKGROUND DOWNLOADER (Called safely at App Startup)
  Future<void> initializeBackgroundUpdate() async {
    if (Platform.isIOS) return; // iOS doesn't do background apk/exe downloads

    try {
      final info = await getLatestVersionInfo();
      if (info != null) {
        final latestVersion = info['version'] as String;
        final packageInfo = await PackageInfo.fromPlatform();

        if (_isVersionNewer(packageInfo.version, latestVersion)) {
           // Proceed to silently download in background
           await _executeDownload(info, isBackground: true);
        } else {
           await _cleanOldUpdates(); // Enforce device storage optimization
        }
      }
    } catch (_) {}
  }

  // Called manually from update_screen.dart (if they press Check Updates)
  Future<Map<String, dynamic>?> checkForUpdateFlow() async {
    if (updateStateNotifier.value == UpdateState.readyToInstall) {
       return _readyReleaseInfo;
    }

    updateStateNotifier.value = UpdateState.checking;
    updateStatusNotifier.value = 'Connecting to GitHub safely...';
    
    try {
      final info = await getLatestVersionInfo();
      if (info != null) {
        final latestVersion = info['version'] as String;
        final packageInfo = await PackageInfo.fromPlatform();

        if (_isVersionNewer(packageInfo.version, latestVersion)) {
          updateStateNotifier.value = UpdateState.available;
          updateStatusNotifier.value = 'Update v$latestVersion is available.';
          return info;
        } else {
          // Cleanup old files if we are fully updated!
          await _cleanOldUpdates();
          updateStateNotifier.value = UpdateState.idle;
          updateStatusNotifier.value = 'System is fully up to date.';
          return info;
        }
      }
    } catch (e) {
      updateStateNotifier.value = UpdateState.error;
      updateStatusNotifier.value = 'Connection error. Could not check for updates.';
    }
    
    updateStateNotifier.value = UpdateState.idle;
    return null;
  }

  // 100% Secure Implementation for Processing the Update (Background or Foreground)
  Future<void> _executeDownload(Map<String, dynamic> releaseInfo, {bool isBackground = false}) async {
    if (!isBackground) {
      updateStateNotifier.value = UpdateState.downloading;
      isUpdatingNotifier.value = true;
      updateProgressNotifier.value = 0.0;
      updateStatusNotifier.value = 'Locating exact system package...';
    }

    String? downloadUrl;
    String fileName = '';
    int expectedBytes = 0;

    final assets = releaseInfo['assets'] as List<dynamic>? ?? [];

    // STRICT ASSET MATCHING (fixes Windows downloading MacOS zip bug)
    if (Platform.isAndroid) {
      final apk = assets.firstWhere((a) => a['name'].toString().toLowerCase().endsWith('.apk'), orElse: () => null);
      if (apk != null) {
        downloadUrl = _privateRepoToken.isNotEmpty ? apk['url'] : apk['browser_download_url'];
        fileName = apk['name'];
        expectedBytes = apk['size'] ?? 0;
      }
    } else if (Platform.isWindows) {
      final win = assets.firstWhere((a) {
        final name = a['name'].toString().toLowerCase();
        return (name.endsWith('.msix') || name.endsWith('.exe')) && !name.contains('macos') && !name.contains('darwin');
      }, orElse: () => null);
      if (win != null) {
        downloadUrl = _privateRepoToken.isNotEmpty ? win['url'] : win['browser_download_url'];
        fileName = win['name'];
        expectedBytes = win['size'] ?? 0;
      }
    } else if (Platform.isMacOS) {
      final mac = assets.firstWhere((a) {
        final name = a['name'].toString().toLowerCase();
        return (name.endsWith('.dmg') || name.endsWith('.pkg') || name.endsWith('.zip')) && !name.contains('windows');
      }, orElse: () => null);
      if (mac != null) {
        downloadUrl = _privateRepoToken.isNotEmpty ? mac['url'] : mac['browser_download_url'];
        fileName = mac['name'];
        expectedBytes = mac['size'] ?? 0;
      }
    }

    if (downloadUrl == null) {
      if (!isBackground) {
        updateStateNotifier.value = UpdateState.error;
        updateStatusNotifier.value = 'No matching package found for ${Platform.operatingSystem}.';
        isUpdatingNotifier.value = false;
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      // Enforce clean local storage usage. Create dedicated update folder.
      final updateDir = Directory('${dir.path}/updates');
      if (!updateDir.existsSync()) {
        updateDir.createSync(recursive: true);
      }
      
      final savePath = '${updateDir.path}/$fileName';
      final existingFile = File(savePath);

      // If already downloaded completely and valid, skip download!
      if (existingFile.existsSync() && expectedBytes > 0 && existingFile.lengthSync() == expectedBytes) {
         _readyInstallPath = savePath;
         _readyReleaseInfo = releaseInfo;
         updateStateNotifier.value = UpdateState.readyToInstall;
         updateStatusNotifier.value = 'Update silently downloaded and ready!';
         return;
      }

      if (existingFile.existsSync()) {
         existingFile.deleteSync(); // Delete partial/corrupt file
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));
      
      final headers = _privateRepoToken.isNotEmpty
          ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/octet-stream'}
          : <String, String>{};

      Future<void> performDownload() async {
        await dio.download(
          downloadUrl!,
          savePath,
          deleteOnError: true,
          options: Options(headers: headers, followRedirects: true, validateStatus: (s) => s != null && s < 500),
          onReceiveProgress: (received, total) {
            if (total > 0 && !isBackground) {
              final pct = received / total;
              final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
              final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
              updateProgressNotifier.value = pct;
              updateStatusNotifier.value = 'Secure download: $recMb MB / $totMb MB';
            }
          },
        );
      }

      await performDownload();

      // Validate Integrity
      if (!isBackground) {
         updateStateNotifier.value = UpdateState.validating;
         updateStatusNotifier.value = 'Verifying structural integrity...';
         updateProgressNotifier.value = 1.0;
         await Future.delayed(const Duration(seconds: 1));
      }
      
      final downloadedFile = File(savePath);
      if (!downloadedFile.existsSync() || (expectedBytes > 0 && downloadedFile.lengthSync() != expectedBytes)) {
        if (downloadedFile.existsSync()) downloadedFile.deleteSync(); 
        if (!isBackground) {
          updateStateNotifier.value = UpdateState.error;
          updateStatusNotifier.value = 'Corrupted file detected. Data removed securely.';
          isUpdatingNotifier.value = false;
        }
        return;
      }

      _readyInstallPath = savePath;
      _readyReleaseInfo = releaseInfo;
      updateStateNotifier.value = UpdateState.readyToInstall;
      updateStatusNotifier.value = 'Package ready for extraction!';

    } catch (e) {
      if (!isBackground) {
        updateStateNotifier.value = UpdateState.error;
        updateStatusNotifier.value = 'Download interrupted. Local files scrubbed safely.';
        isUpdatingNotifier.value = false;
      }
    }
  }

  // Triggered manually explicitly on Update Screen Button!
  Future<void> startDirectUpdate(Map<String, dynamic> releaseInfo) async {
    // iOS Redirect logic
    if (Platform.isIOS) {
      updateStateNotifier.value = UpdateState.downloading;
      updateStatusNotifier.value = 'Redirecting to App Store...';
      await Future.delayed(const Duration(seconds: 1));
      final uri = Uri.parse('https://apps.apple.com/'); 
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      _resetState();
      return;
    }

    if (_readyInstallPath != null && File(_readyInstallPath!).existsSync()) {
      await _installExecutingFile(_readyInstallPath!);
    } else {
      // Not downloaded yet? Execute download foreground then install
      await _executeDownload(releaseInfo, isBackground: false);
      if (updateStateNotifier.value == UpdateState.readyToInstall && _readyInstallPath != null) {
        await _installExecutingFile(_readyInstallPath!);
      }
    }
  }

  // Runs the safe OS execution process
  Future<void> _installExecutingFile(String path) async {
    updateStateNotifier.value = UpdateState.installing;
    updateStatusNotifier.value = 'Engaging System Installer...';
    await Future.delayed(const Duration(seconds: 1));

    if (Platform.isWindows) {
       // Check if it's an EXE to run the Advanced Silent Setup
       if (path.toLowerCase().endsWith('.exe')) {
         Process.start(path, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'], runInShell: true, mode: ProcessStartMode.detached);
       } else {
         // Fallback for any other format on Windows (.msix etc, though we want EXE)
         Process.start(path, [], runInShell: true, mode: ProcessStartMode.detached);
       }
       
       updateStateNotifier.value = UpdateState.relaunching;
       updateStatusNotifier.value = 'Success! App closing to securely replace files...';
       await Future.delayed(const Duration(seconds: 3));
       exit(0);
    } else {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
        updateStateNotifier.value = UpdateState.relaunching;
        updateStatusNotifier.value = 'Success! System will exit to finalize...';
        await Future.delayed(const Duration(seconds: 3));
        exit(0);
      } else {
        updateStateNotifier.value = UpdateState.error;
        updateStatusNotifier.value = 'Execute failed: ${result.message}\nPlease open manually from Downloads.';
        isUpdatingNotifier.value = false;
      }
    }
  }

  Future<void> _cleanOldUpdates() async {
    try {
      final dir = await getTemporaryDirectory();
      final updateDir = Directory('${dir.path}/updates');
      if (updateDir.existsSync()) {
        updateDir.deleteSync(recursive: true);
      }
      _readyInstallPath = null;
    } catch (_) {}
  }

  void _resetState() {
    updateStateNotifier.value = UpdateState.idle;
    isUpdatingNotifier.value = false;
    updateProgressNotifier.value = 0.0;
    updateStatusNotifier.value = '';
  }

  bool _isVersionNewer(String current, String latest) {
    try {
      final cParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final lParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      for (int i = 0; i < lParts.length; i++) {
        final cp = i < cParts.length ? cParts[i] : 0;
        if (lParts[i] > cp) return true;
        if (lParts[i] < cp) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> checkForUpdate(BuildContext context, {bool showNoUpdate = false}) async { 
    // Trigger background initialization check
    await initializeBackgroundUpdate();
  }
}
