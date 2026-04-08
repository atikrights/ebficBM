import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

enum UpdateState { idle, checking, available, downloading, validating, readyToInstall, installing, relaunching, error }

final ValueNotifier<UpdateState> updateStateNotifier = ValueNotifier(UpdateState.idle);
final ValueNotifier<double> updateProgressNotifier = ValueNotifier(0.0);
final ValueNotifier<String> updateStatusNotifier = ValueNotifier('');
final ValueNotifier<bool> isUpdatingNotifier = ValueNotifier(false);

class UpdateService {
  static const String _updateUrl = 'https://api.github.com/repos/atikrights/ebficBM/releases';

  // ✅ SECURE: Token is injected at compile-time via --dart-define=GITHUB_TOKEN=xxx
  static const String _privateRepoToken = String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // Initialize and check in background
  Future<void> initializeBackgroundUpdate() async {
    try {
      final updateInfo = await checkForUpdateFlow();
      final current = await _currentVersion;
      if (updateInfo != null && _isVersionNewer(current, updateInfo['version'])) {
        await startDirectUpdate(updateInfo);
      } else {
        await _cleanOldUpdates();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> checkForUpdateFlow() async {
    updateStateNotifier.value = UpdateState.checking;
    final releases = await getReleases();
    
    if (releases == null || releases.isEmpty) {
      updateStateNotifier.value = UpdateState.idle;
      return null;
    }

    final latest = releases.first;
    final String version = (latest['tag_name'] as String).replaceAll('v', '');
    final List assets = latest['assets'];
    
    Map<String, dynamic>? platformAsset;
    
    if (Platform.isWindows) {
      platformAsset = assets.firstWhere((a) => a['name'].toString().toLowerCase().endsWith('.exe'), orElse: () => null);
    } else if (Platform.isAndroid) {
      platformAsset = assets.firstWhere((a) => a['name'].toString().toLowerCase().endsWith('.apk'), orElse: () => null);
    } else if (Platform.isMacOS) {
      platformAsset = assets.firstWhere((a) => a['name'].toString().toLowerCase().endsWith('.zip') && a['name'].toString().toLowerCase().contains('macos'), orElse: () => null);
    }

    if (platformAsset == null) {
      updateStateNotifier.value = UpdateState.idle;
      return null;
    }

    final info = {
      'version': version,
      'url': platformAsset['url'],
      'browser_download_url': platformAsset['browser_download_url'],
      'name': platformAsset['name'],
      'size': platformAsset['size'],
      'sizeMb': (platformAsset['size'] / (1024 * 1024)).toStringAsFixed(1),
      'notes': latest['body'],
      'author': latest['author']['login'],
      'author_avatar': latest['author']['avatar_url'],
    };

    final current = await _currentVersion;
    updateStateNotifier.value = _isVersionNewer(current, version) ? UpdateState.available : UpdateState.idle;
    return info;
  }

  Future<List<Map<String, dynamic>>?> getReleases() async {
    try {
      final headers = _privateRepoToken.isNotEmpty 
        ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/vnd.github.v3+json'}
        : {'Accept': 'application/vnd.github.v3+json'};
        
      final response = await Dio().get(_updateUrl, options: Options(headers: headers));
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('Update Check Failed: $e');
      return null;
    }
  }

  Future<void> startDirectUpdate(Map<String, dynamic> info) async {
    if (isUpdatingNotifier.value) return;
    isUpdatingNotifier.value = true;

    try {
      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory('${tempDir.path}/updates');
      if (!await updateDir.exists()) await updateDir.create();

      final filePath = '${updateDir.path}/${info['name']}';
      final file = File(filePath);

      // Secure comparison: Verify if file already fully downloaded and correct size
      if (await file.exists() && await file.length() == info['size']) {
        updateStateNotifier.value = UpdateState.readyToInstall;
        updateStatusNotifier.value = 'Update downloaded! Ready to install.';
        return;
      }

      // Download start
      updateStateNotifier.value = UpdateState.downloading;
      updateStatusNotifier.value = 'Connecting to secure server...';
      
      final headers = _privateRepoToken.isNotEmpty 
        ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/octet-stream'}
        : {'Accept': 'application/octet-stream'};

      String downloadUrl = _privateRepoToken.isNotEmpty ? info['url'] : info['browser_download_url'];

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
      ));

      await dio.download(
        downloadUrl,
        filePath,
        options: Options(headers: headers),
        onReceiveProgress: (count, total) {
          if (total != -1) {
            updateProgressNotifier.value = count / total;
            updateStatusNotifier.value = 'Downloading: ${(count / (1024 * 1024)).toStringAsFixed(1)}MB / ${(total / (1024 * 1024)).toStringAsFixed(1)}MB';
          }
        },
      );

      // Verify integrity
      updateStateNotifier.value = UpdateState.validating;
      updateStatusNotifier.value = 'Verifying integrity...';
      await Future.delayed(const Duration(seconds: 1));

      if (await file.length() == info['size']) {
        updateStateNotifier.value = UpdateState.readyToInstall;
        updateStatusNotifier.value = 'Ready to install.';
      } else {
        throw Exception('File integrity check failed (Size mismatch)');
      }
    } catch (e) {
      updateStateNotifier.value = UpdateState.error;
      updateStatusNotifier.value = 'Download Failed: $e';
      isUpdatingNotifier.value = false;
    }
  }

  Future<void> installUpdate(Map<String, dynamic> info) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/updates/${info['name']}';
    _installExecutingFile(filePath);
  }

  Future<void> _installExecutingFile(String path) async {
    updateStateNotifier.value = UpdateState.installing;
    updateStatusNotifier.value = 'Engaging System Installer...';
    await Future.delayed(const Duration(seconds: 1));

    if (Platform.isWindows) {
      if (path.toLowerCase().endsWith('.exe')) {
        await Process.start(path, ['/VERYSILENT', '/SUPPRESSMSGBOXES'], 
          runInShell: true, mode: ProcessStartMode.detached);
      } else {
        await Process.start(path, [], runInShell: true, mode: ProcessStartMode.detached);
      }
      updateStateNotifier.value = UpdateState.relaunching;
      updateStatusNotifier.value = 'Success! App closing to replace files...';
      await Future.delayed(const Duration(seconds: 3));
      exit(0);
    } else {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
        updateStateNotifier.value = UpdateState.relaunching;
        updateStatusNotifier.value = 'Success! Device relaunching...';
        await Future.delayed(const Duration(seconds: 3));
        exit(0);
      } else {
        updateStateNotifier.value = UpdateState.error;
        updateStatusNotifier.value = 'Execution failed: ${result.message}';
        isUpdatingNotifier.value = false;
      }
    }
  }

  Future<void> _cleanOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory('${tempDir.path}/updates');
      if (await updateDir.exists()) {
        await updateDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<String> get _currentVersion async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  bool _isVersionNewer(String current, String online) {
    try {
      List<int> curr = current.split('.').map(int.parse).toList();
      List<int> next = online.split('.').map(int.parse).toList();
      for (int i = 0; i < curr.length && i < next.length; i++) {
        if (next[i] > curr[i]) return true;
        if (next[i] < curr[i]) return false;
      }
      return next.length > curr.length;
    } catch (_) {
      return online != current;
    }
  }
}
