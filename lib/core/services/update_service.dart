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

  Future<List<Map<String, dynamic>>?> getReleases() async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 15));
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
      String tagName = latest['tag_name'] ?? '';
      if (tagName.startsWith('v')) tagName = tagName.substring(1);
      
      // Calculate size for mb (using assets size)
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
        _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes, sizeMb, assets);
      } else if (showNoUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your app is up to date!')),
        );
      }
    }
  }

  bool _isVersionNewer(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > currentPart) return true;
      if (latestParts[i] < currentPart) return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String version, String url, String notes, String sizeMb, List<dynamic> assets) {
    bool isDownloading = false;
    double progress = 0.0;
    String status = "Ready to update";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text('New Update Available!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $version ($sizeMb MB) is now available.', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('What\'s new:'),
                Text(notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress, color: Colors.blueAccent),
                  const SizedBox(height: 8),
                  Text(status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                      downloadUrl = apkAsset['browser_download_url'];
                      fileName = apkAsset['name'];
                    }
                  } else if (Platform.isWindows) {
                    final zipAsset = assets.firstWhere((a) => a['name'].toString().endsWith('.zip') || a['name'].toString().endsWith('.exe'), orElse: () => null);
                    if (zipAsset != null) {
                      downloadUrl = zipAsset['browser_download_url'];
                      fileName = zipAsset['name'];
                    }
                  }

                  if (downloadUrl == null) {
                    // Fallback to browser if no asset found
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
                    await dio.download(
                      downloadUrl,
                      savePath,
                      onReceiveProgress: (received, total) {
                        if (total != -1) {
                          setState(() {
                            progress = received / total;
                            status = "Downloading ${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB";
                          });
                        }
                      },
                    );

                    setState(() => status = "Installing...");
                    final result = await OpenFilex.open(savePath);
                    if (result.type != ResultType.done) {
                        setState(() {
                          isDownloading = false;
                          status = "Failed to open file";
                        });
                    } else {
                       if (context.mounted) Navigator.pop(context);
                    }
                  } catch (e) {
                    setState(() {
                      isDownloading = false;
                      status = "Download failed!";
                    });
                  }
                },
                child: Text(isDownloading ? 'Please wait...' : 'Update Now'),
              ),
            ],
          );
        }
      ),
    );
  }
}
