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
  String _currentVersion = '...';
  Map<String, dynamic>? _onlineInfo;
  bool _isLoading = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final info = await UpdateService().getLatestVersionInfo();
    if (mounted) {
      setState(() {
        _currentVersion = packageInfo.version;
        _onlineInfo = info;
        _isLoading = false;
      });
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
        : ListView( // Changed to ListView for better scrolling and no overflow
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.system_update_rounded, size: 100, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      'v$_currentVersion',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Current Installed Version', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Update Status
              _buildSection(
                title: 'Check for Updates',
                child: Column(
                  children: [
                    if (_onlineInfo != null && _onlineInfo!['version'] != _currentVersion)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Version ${_onlineInfo!['version']} is available!', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    const Text('Keep your app up to date to access the latest business tools and security enhancements.'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : () async {
                          setState(() => _isChecking = true);
                          await UpdateService().checkForUpdate(context, showNoUpdate: true);
                          await _initialFetch(); // Refresh local state
                          setState(() => _isChecking = false);
                        },
                        icon: _isChecking 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Icon(Icons.sync_rounded),
                        label: Text(_isChecking ? 'Checking GitHub...' : 'Check Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Update Activity (Realtime from GitHub)
              _buildSection(
                title: 'Update Activity',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_onlineInfo != null) ...[
                      _buildUpdateItem('Latest Release', _onlineInfo!['notes'] ?? 'General improvements and bug fixes.'),
                      const Divider(height: 32),
                    ],
                    _buildUpdateItem('v1.0.1', 'Core dashboard and project management modules.'),
                    _buildUpdateItem('v1.0.2', 'Added automated update engine.'),
                  ],
                ),
              ),

              const SizedBox(height: 60),
              
              // Footer
              Center(
                child: Text(
                  'Thanks for Atik Islam',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.withOpacity(0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 14, color: Colors.blueAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
