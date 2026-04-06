import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bizos_x_pro/core/services/update_service.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  String _currentVersion = '';
  Map<String, dynamic>? _onlineInfo;
  bool _isLoading = true;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final info = await UpdateService().getLatestVersionInfo();
      if (mounted) {
        setState(() {
          _currentVersion = packageInfo.version;
          _onlineInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not connect. Check your internet.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Update'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initialFetch,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),

                  // Version header
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.system_update_rounded,
                            size: 80, color: Colors.blueAccent),
                        const SizedBox(height: 12),
                        Text(
                          _currentVersion.isNotEmpty
                              ? 'v$_currentVersion'
                              : 'ebficBM',
                          style: GoogleFonts.outfit(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text('Current Installed Version',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error banner
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_errorMessage!,
                                style:
                                    const TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                    ),

                  // Update available banner
                  if (_onlineInfo != null &&
                      _onlineInfo!['version'] != null &&
                      _currentVersion.isNotEmpty &&
                      _onlineInfo!['version'] != _currentVersion)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.new_releases, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'v${_onlineInfo!['version']} is available!',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                                if ((_onlineInfo!['sizeMb'] ?? '0.0') != '0.0')
                                  Text(
                                    'Size: ${_onlineInfo!['sizeMb']} MB',
                                    style: const TextStyle(
                                        color: Colors.green, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Check for update section
                  _buildSection(
                    title: 'Check for Updates',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep your app up to date for the latest features and security patches.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isChecking
                                ? null
                                : () async {
                                    if (!mounted) return;
                                    setState(() => _isChecking = true);
                                    try {
                                      await UpdateService().checkForUpdate(
                                          context,
                                          showNoUpdate: true);
                                      await _initialFetch();
                                    } catch (_) {}
                                    if (mounted) {
                                      setState(() => _isChecking = false);
                                    }
                                  },
                            icon: _isChecking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.sync_rounded),
                            label:
                                Text(_isChecking ? 'Checking...' : 'Check Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Update Activity
                  _buildSection(
                    title: 'Update Activity',
                    child: _buildActivityList(),
                  ),

                  const SizedBox(height: 48),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ebfic Business Manager',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.withOpacity(0.8),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by Atik Islam  \u2022  ebfic Group Limited',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey.withOpacity(0.5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildActivityList() {
    try {
      final releases = _onlineInfo?['all_releases'] as List?;

      if (releases == null || releases.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No release activity found.\nPull down to refresh.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        );
      }

      return Column(
        children: releases.take(10).map((release) {
          final vName = (release['tag_name'] ?? '').toString();
          final rawBody = (release['body'] ?? '').toString();
          // Clean markdown special characters that cause Android rendering issues
          final body = rawBody
              .replaceAll('\r\n', ' ')
              .replaceAll('\n', ' ')
              .replaceAll('**', '')
              .replaceAll('##', '')
              .replaceAll('`', '')
              .replaceAll('|', '')
              .trim();

          return Column(
            children: [
              _buildUpdateItem(
                vName.isEmpty ? 'Release' : vName,
                body.isEmpty ? 'General improvements and bug fixes.' : body,
              ),
              const Divider(height: 24),
            ],
          );
        }).toList(),
      );
    } catch (e) {
      return const Text(
        'Could not load activity.',
        style: TextStyle(color: Colors.grey),
      );
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
