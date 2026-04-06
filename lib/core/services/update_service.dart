import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Replace this with your actual GitHub raw URL for version.json
  static const String _updateUrl = 'https://raw.githubusercontent.com/atikrights/ebficBM/main/version.json';

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_updateUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String;
        final downloadUrl = data['url'] as String;
        final releaseNotes = data['notes'] as String;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isVersionNewer(currentVersion, latestVersion)) {
          _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
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

  void _showUpdateDialog(BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
            Text('Version $version is now available.', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('What\'s new:'),
            Text(notes, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
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
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
