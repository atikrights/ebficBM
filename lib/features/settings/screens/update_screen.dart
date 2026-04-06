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
  String _currentVersion = 'Loading...';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Update'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.system_update_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              'Current Version: $_currentVersion',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Update Section
            _buildSection(
              title: 'Update Section',
              child: Column(
                children: [
                  const Text('Keep your app up to date for the latest features and security patches.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : () async {
                      setState(() => _isChecking = true);
                      await UpdateService().checkForUpdate(context);
                      setState(() => _isChecking = false);
                    },
                    icon: _isChecking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                    label: Text(_isChecking ? 'Checking...' : 'Check for Updates'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Update Activity
            _buildSection(
              title: 'Update Activity',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUpdateItem('v1.0.1', 'Initial public release with core business management features.'),
                  _buildUpdateItem('v1.0.2', 'Added automated update system and dedicated update page.'),
                  _buildUpdateItem('Upcoming', 'Cloud sync and multi-user login support.'),
                ],
              ),
            ),

            const SizedBox(height: 50),
            
            // Footer
            Text(
              'Thanks for Atik Islam',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String version, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(version, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
