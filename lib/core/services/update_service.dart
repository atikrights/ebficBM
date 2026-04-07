import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// ─── Global notifiers so update_screen.dart can listen in real-time ───────────
final ValueNotifier<double> updateProgressNotifier = ValueNotifier(0.0);
final ValueNotifier<String> updateStatusNotifier = ValueNotifier('');
final ValueNotifier<bool> isUpdatingNotifier = ValueNotifier(false);

class UpdateService {
  static const String _updateUrl =
      'https://api.github.com/repos/atikrights/ebficBM/releases';
  // Private repo token — Read-Only Fine-Grained GitHub PAT
  static const String _privateRepoToken =
      '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';

  Future<List<Map<String, dynamic>>?> getReleases() async {
    try {
      final noCacheUrl =
          '$_updateUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = _privateRepoToken.isNotEmpty
          ? {
              'Authorization': 'Bearer $_privateRepoToken',
              'Accept': 'application/vnd.github.v3+json'
            }
          : {'Accept': 'application/vnd.github.v3+json'};

      final response = await http
          .get(Uri.parse(noCacheUrl), headers: headers)
          .timeout(const Duration(seconds: 15));
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
        'notes': latest['body'] ?? 'Auto update',
        'sizeMb': totalSizeMb.toStringAsFixed(1),
        'all_releases': releases,
        'assets': latest['assets'],
      };
    }
    return null;
  }

  Future<void> checkForUpdate(BuildContext context,
      {bool showNoUpdate = false}) async {
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
            _showUpdateDialog(
                context, latestVersion, downloadUrl, releaseNotes, sizeMb, assets);
          }
        } else if (showNoUpdate) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Your app is up to date!'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
      final currentParts =
          current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final latestParts =
          latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < latestParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
      }
    } catch (_) {}
    return false;
  }

  void _showUpdateDialog(BuildContext context, String version, String url,
      String notes, String sizeMb, List<dynamic> assets) {
    // Reset global notifiers
    updateProgressNotifier.value = 0.0;
    updateStatusNotifier.value = '';
    isUpdatingNotifier.value = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UpdateDialog(
        version: version,
        url: url,
        notes: notes,
        sizeMb: sizeMb,
        assets: assets,
        privateToken: _privateRepoToken,
      ),
    );
  }
}

// ─── Premium Real-Time Update Dialog ─────────────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  final String version;
  final String url;
  final String notes;
  final String sizeMb;
  final List<dynamic> assets;
  final String privateToken;

  const _UpdateDialog({
    required this.version,
    required this.url,
    required this.notes,
    required this.sizeMb,
    required this.assets,
    required this.privateToken,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isDone = false;
  bool _hasError = false;
  double _progress = 0.0;
  String _statusText = '';
  String _receivedMb = '';
  String _totalMb = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _statusText = 'Searching for download link...';
      _progress = 0.0;
    });

    // Also update global notifiers for update_screen real-time
    isUpdatingNotifier.value = true;
    updateStatusNotifier.value = 'Searching for download link...';
    updateProgressNotifier.value = 0.0;

    String? downloadUrl;
    String fileName = '';

    final assets = widget.assets;
    if (Platform.isAndroid) {
      final apk = assets.firstWhere(
          (a) => a['name'].toString().endsWith('.apk'),
          orElse: () => null);
      if (apk != null) {
        downloadUrl = widget.privateToken.isNotEmpty
            ? apk['url']
            : apk['browser_download_url'];
        fileName = apk['name'];
      }
    } else if (Platform.isWindows) {
      final win = assets.firstWhere(
          (a) =>
              a['name'].toString().endsWith('.msix') ||
              a['name'].toString().endsWith('.exe') ||
              a['name'].toString().endsWith('.zip'),
          orElse: () => null);
      if (win != null) {
        downloadUrl = widget.privateToken.isNotEmpty
            ? win['url']
            : win['browser_download_url'];
        fileName = win['name'];
      }
    } else if (Platform.isMacOS) {
      final mac = assets.firstWhere(
          (a) =>
              a['name'].toString().endsWith('.dmg') ||
              a['name'].toString().endsWith('.pkg') ||
              a['name'].toString().endsWith('.zip'),
          orElse: () => null);
      if (mac != null) {
        downloadUrl = widget.privateToken.isNotEmpty
            ? mac['url']
            : mac['browser_download_url'];
        fileName = mac['name'];
      }
    }

    // Fallback: open browser
    if (downloadUrl == null) {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) Navigator.pop(context);
      isUpdatingNotifier.value = false;
      return;
    }

    _updateStatus('Starting download...', 0.02);

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName';

      // Use a more robust Dio configuration
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));
      
      final headers = widget.privateToken.isNotEmpty
          ? {
              'Authorization': 'Bearer ${widget.privateToken}',
              'Accept': 'application/octet-stream'
            }
          : <String, String>{};

      // Internal helper for retry logic
      Future<void> performDownload() async {
        await dio.download(
          downloadUrl!,
          savePath,
          deleteOnError: true,
          options: Options(
            headers: headers,
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              final pct = received / total;
              final rec = (received / (1024 * 1024)).toStringAsFixed(1);
              final tot = (total / (1024 * 1024)).toStringAsFixed(1);
              setState(() {
                _progress = pct;
                _receivedMb = rec;
                _totalMb = tot;
                _statusText =
                    'Downloading... $rec MB / $tot MB (${(pct * 100).toStringAsFixed(0)}%)';
              });
              updateProgressNotifier.value = pct;
              updateStatusNotifier.value =
                  'Downloading $rec MB / $tot MB (${(pct * 100).toStringAsFixed(0)}%)';
            }
          },
        );
      }

      // Execute with a single automatic retry on connection reset
      try {
        await performDownload();
      } catch (e) {
        debugPrint('First download attempt failed, retrying once... $e');
        await Future.delayed(const Duration(seconds: 2));
        await performDownload();
      }

      _updateStatus('Download complete! Installing...', 1.0);
      await Future.delayed(const Duration(milliseconds: 600));

      final result = await OpenFilex.open(savePath);
      if (result.type == ResultType.done) {
        if (mounted) {
          setState(() {
            _isDone = true;
            _isDownloading = false;
            _statusText = 'Relaunching System...';
          });
          updateStatusNotifier.value = 'Relaunching System...';
          isUpdatingNotifier.value = false;
          
          // Give user a moment to see the success, then exit to let the installer finish
          await Future.delayed(const Duration(seconds: 2));
          exit(0); 
        }
      } else {
        _setError('Install failed: ${result.message}\nPath: $savePath');
      }
    } catch (e) {
      String errStr = e.toString();
      if (errStr.contains('Connection closed')) {
        _setError('Connection was interrupted. Please check your internet and click Retry.');
      } else {
        _setError('Download failed: $errStr');
      }
    }
  }

  void _updateStatus(String msg, double progress) {
    if (!mounted) return;
    setState(() {
      _statusText = msg;
      _progress = progress;
    });
    updateStatusNotifier.value = msg;
    updateProgressNotifier.value = progress;
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _isDownloading = false;
      _statusText = msg;
    });
    isUpdatingNotifier.value = false;
    updateStatusNotifier.value = msg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final surface = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF5F7FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header gradient ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.system_update_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Available',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'v${widget.version}  •  ${widget.sizeMb} MB',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What's new
                    if (!_isDownloading && !_isDone) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("What's new",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              widget.notes
                                  .replaceAll('**', '')
                                  .replaceAll('##', '')
                                  .replaceAll('`', '')
                                  .replaceAll('|', ' ')
                                  .replaceAll('\r\n', '\n')
                                  .trim(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  height: 1.5),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Real-time download progress ───────────────
                    if (_isDownloading) ...[
                      const SizedBox(height: 4),
                      // Animated progress bar
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 10,
                            width: MediaQuery.of(context).size.width *
                                _progress *
                                0.7,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2563EB).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700]),
                            ),
                          ),
                          if (_totalMb.isNotEmpty)
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Pulsing download animation indicator
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _receivedMb.isNotEmpty
                                        ? '$_receivedMb MB / $_totalMb MB'
                                        : 'Preparing...',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Success state ─────────────────────────────
                    if (_isDone) ...[
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 52),
                            SizedBox(height: 10),
                            Text('Update installed!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Relaunching the installer...',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Error state ───────────────────────────────
                    if (_hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_statusText,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Action buttons ────────────────────────────
                    if (!_isDownloading && !_isDone)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Later',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _hasError ? _startDownload : _startDownload,
                              icon: Icon(_hasError
                                  ? Icons.refresh_rounded
                                  : Icons.download_rounded),
                              label: Text(
                                  _hasError ? 'Retry' : 'Update Now',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
