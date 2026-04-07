import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String _updateUrl = 'https://api.github.com/repos/atikrights/ebficBM/releases';
  // Private repo token — Read-Only Fine-Grained GitHub PAT
  static const String _privateRepoToken = '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';

  Future<List<Map<String, dynamic>>?> getReleases() async {
    try {
      final String noCacheUrl = '$_updateUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = _privateRepoToken.isNotEmpty 
          ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/vnd.github.v3+json'} 
          : {'Accept': 'application/vnd.github.v3+json'};
          
      final response = await http.get(Uri.parse(noCacheUrl), headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
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
        'notes': latest['body'] ?? 'Auto update',
        'sizeMb': totalSizeMb.toStringAsFixed(1),
        'all_releases': releases,
        'assets': latest['assets'],
      };
    }
    return null;
  }

  Future<void> checkForUpdate(BuildContext context, {bool showNoUpdate = false}) async {
    try {
      final info = await getLatestVersionInfo();
      if (info != null) {
        final latestVersion = info['version'] as String;
        final downloadUrl = info['url'] as String;
        final releaseNotes = info['notes'] as String;
        final sizeMb = info['sizeMb'] as String? ?? 'Unknown';
        final assets = info['assets'] as List<dynamic>? ?? [];

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isVersionNewer(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes, sizeMb, assets);
          }
        } else if (showNoUpdate) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your app is up to date!')),
            );
          }
        }
      }
    } catch (e) {
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking updates: $e')),
        );
      }
    }
  }

  bool _isVersionNewer(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String version, String url, String notes, String sizeMb, List<dynamic> assets) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isDownloading = false;
          double progress = 0.0;
          String status = "Ready to update";

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.system_update, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text('New Update Available!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $version ($sizeMb MB) is now available.', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('What\'s new:'),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    child: Text(notes, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  ),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress, color: Colors.blueAccent, backgroundColor: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Text(status, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ]
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isDownloading ? null : () async {
                  setState(() {
                    isDownloading = true;
                    status = "Finding download link...";
                  });

                  String? downloadUrl;
                  String fileName = '';
                  
                  if (Platform.isAndroid) {
                    final apkAsset = assets.firstWhere((a) => a['name'].toString().endsWith('.apk'), orElse: () => null);
                    if (apkAsset != null) {
                      downloadUrl = _privateRepoToken.isNotEmpty ? apkAsset['url'] : apkAsset['browser_download_url'];
                      fileName = apkAsset['name'];
                    }
                  } else if (Platform.isWindows) {
                    final installAsset = assets.firstWhere((a) => a['name'].toString().endsWith('.msix') || a['name'].toString().endsWith('.exe') || a['name'].toString().endsWith('.zip'), orElse: () => null);
                    if (installAsset != null) {
                      downloadUrl = _privateRepoToken.isNotEmpty ? installAsset['url'] : installAsset['browser_download_url'];
                      fileName = installAsset['name'];
                    }
                  } else if (Platform.isMacOS) {
                    final macAsset = assets.firstWhere((a) => a['name'].toString().endsWith('.dmg') || a['name'].toString().endsWith('.pkg'), orElse: () => null);
                    if (macAsset != null) {
                      downloadUrl = _privateRepoToken.isNotEmpty ? macAsset['url'] : macAsset['browser_download_url'];
                      fileName = macAsset['name'];
                    }
                  } else if (Platform.isIOS) {
                    // Apple strictly forbids in-app sideloading. Fallback to browser/AppStore immediately.
                    downloadUrl = null;
                  }

                  if (downloadUrl == null) {
                     final uri = Uri.parse(url);
                     if (await canLaunchUrl(uri)) {
                       await launchUrl(uri, mode: LaunchMode.externalApplication);
                     }
                     if (context.mounted) Navigator.pop(context);
                     return;
                  }

                  setState(() => status = "Downloading...");

                  try {
                    final dir = await getTemporaryDirectory();
                    final savePath = '${dir.path}/$fileName';
                    
                    final dio = Dio();
                    final headers = _privateRepoToken.isNotEmpty 
                        ? {'Authorization': 'Bearer $_privateRepoToken', 'Accept': 'application/octet-stream'}
                        : <String, String>{};

                    await dio.download(
                      downloadUrl,
                      savePath,
                      options: Options(headers: headers),
                      onReceiveProgress: (received, total) {
                        if (total != -1) {
                          if (context.mounted) {
                            setState(() {
                              progress = received / total;
                              status = "Downloading ${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB";
                            });
                          }
                        }
                      },
                    );

                    if (context.mounted) setState(() => status = "Installing...");
                    
                    final result = await OpenFilex.open(savePath);
                    if (result.type != ResultType.done) {
                        if (context.mounted) {
                          setState(() {
                            isDownloading = false;
                            status = "Error: ${result.message}";
                          });
                        }
                    } else {
                       if (context.mounted) Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() {
                        isDownloading = false;
                        status = "Download failed: $e";
                      });
                    }
                  }
                },
                child: Text(isDownloading ? 'Downloading...' : 'Update Now'),
              ),
            ],
          );
        }
      ),
    );
  }
}
