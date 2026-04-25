import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../widgets/glass_box.dart';

class DatabaseVaultScreen extends StatefulWidget {
  const DatabaseVaultScreen({super.key});

  @override
  State<DatabaseVaultScreen> createState() => _DatabaseVaultScreenState();
}

class _DatabaseVaultScreenState extends State<DatabaseVaultScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _systemStatus;
  List<dynamic> _databases = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // In a real app, this would call the API
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _systemStatus = {
        "storage": {"total": 500, "used": 145, "free": 355, "percent": 29.0},
        "databases": [
          {"database": "ebficbm_prod", "size_mb": 124.5},
          {"database": "ebficbm_audit", "size_mb": 45.2},
        ]
      };
      _databases = [
        {"name": "Production Main", "host": "127.0.0.1", "database_name": "ebficbm_prod", "is_active": true},
        {"name": "Audit Logs", "host": "10.0.0.5", "database_name": "ebficbm_audit", "is_active": true},
      ];
    });
  }

  void _showAddDatabaseDialog() {
    final nameC = TextEditingController();
    final hostC = TextEditingController();
    final dbC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0D0B14).withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AdminTheme.accent.withOpacity(0.2))),
          title: Row(
            children: [
              Icon(IconsaxPlusBold.shield_security, color: AdminTheme.accent, size: 24),
              const SizedBox(width: 12),
              const Text("SECURE DATABASE VAULT", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameC, "Connection Name", IconsaxPlusLinear.tag),
                const SizedBox(height: 16),
                _buildField(hostC, "Database Host (IP/Domain)", IconsaxPlusLinear.global),
                const SizedBox(height: 16),
                _buildField(dbC, "Database Name", IconsaxPlusLinear.driver),
                const SizedBox(height: 16),
                _buildField(userC, "Username", IconsaxPlusLinear.user),
                const SizedBox(height: 16),
                _buildField(passC, "Password", IconsaxPlusLinear.key, isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                // Logic to save
                Navigator.pop(context);
              },
              child: const Text("ENCRYPT & SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AdminTheme.accent, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Security Database Vault", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                const SizedBox(height: 4),
                Text("Military-Grade Encrypted Connection Management", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(IconsaxPlusLinear.add_square, size: 18),
              label: const Text("ADD SECURE DATABASE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _showAddDatabaseDialog,
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildDatabaseList()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildStorageStats()),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDatabaseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACTIVE CONNECTIONS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 16),
        ..._databases.map((db) => _databaseCard(db)).toList(),
      ],
    );
  }

  Widget _databaseCard(Map<String, dynamic> db) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(IconsaxPlusBold.driver, color: AdminTheme.accent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(db['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("${db['host']} • ${db['database_name']}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text("ENCRYPTED", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          IconButton(onPressed: () {}, icon: const Icon(IconsaxPlusLinear.trash, color: Colors.redAccent, size: 20)),
        ],
      ),
    );
  }

  Widget _buildStorageStats() {
    final storage = _systemStatus?['storage'];
    return GlassBox(
      blur: 20,
      opacity: 0.05,
      borderRadius: 24,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SERVER STORAGE HEALTH", style: TextStyle(color: AdminTheme.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 32),
          _storageItem("Total Space", "${storage['total']} GB", Colors.white),
          _storageItem("Used Space", "${storage['used']} GB", AdminTheme.accent),
          _storageItem("Free Space", "${storage['free']} GB", Colors.greenAccent),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
              AnimatedContainer(
                duration: 1.seconds,
                height: 8, 
                width: (MediaQuery.of(context).size.width * 0.2) * (storage['percent'] / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AdminTheme.accent, Colors.orangeAccent]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: AdminTheme.accent.withOpacity(0.5), blurRadius: 10)]
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("${storage['percent']}% Consumed", style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 48),
          const Text("DATABASE SIZES", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...(_systemStatus?['databases'] as List).map((db) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(db['database'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text("${db['size_mb']} MB", style: const TextStyle(color: AdminTheme.accent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _storageItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
