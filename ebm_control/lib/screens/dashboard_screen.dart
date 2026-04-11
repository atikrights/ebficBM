import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatGrid(),
                        const SizedBox(height: 24),
                        _buildMainContentArea(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      color: const Color(0xFF0D0E14),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(IconsaxPlusBold.category, color: AdminTheme.accent, size: 32),
          const SizedBox(height: 48),
          _sidebarItem(IconsaxPlusLinear.element_3, 0),
          _sidebarItem(IconsaxPlusLinear.user, 1),
          _sidebarItem(IconsaxPlusLinear.setting, 2),
          _sidebarItem(IconsaxPlusLinear.monitor, 3),
          const Spacer(),
          _sidebarItem(IconsaxPlusLinear.logout, 99, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, int index, {Color? color}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          icon,
          color: isSelected ? AdminTheme.accent : (color ?? Colors.white38),
          size: 24,
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          const Text(
            "ebfic CONTROL CENTER",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
              color: AdminTheme.textDim,
            ),
          ),
          const Spacer(),
          // System Status Indicators
          _statusChip("SYSTEM LIVE", Colors.greenAccent),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AdminTheme.surface,
            child: Icon(IconsaxPlusLinear.user, size: 18, color: AdminTheme.accent),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(height: 8, width: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard("Active Android", "12,840", Icons.android, Colors.green),
        _statCard("Active Windows", "4,210", Icons.window, Colors.blue),
        _statCard("Web Access", "8,922", Icons.language, Colors.orange),
        _statCard("Total Revenue", "\$48,20.00", Icons.attach_money, Colors.purpleAccent),
      ],
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      width: 200,
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainContentArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-time Logs (Left)
        Expanded(
          flex: 2,
          child: _contentBox("System Logs", _buildLogList()),
        ),
        const SizedBox(width: 24),
        // Feature Toggles (Right)
        Container(
          width: 300,
          child: _contentBox("Control Toggles", _buildToggles()),
        ),
      ],
    );
  }

  Widget _contentBox(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return Column(
      children: List.generate(5, (index) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(radius: 4, backgroundColor: AdminTheme.accent),
        title: Text("User #82${index} logged in from Windows", style: const TextStyle(fontSize: 12)),
        subtitle: Text("2 minutes ago", style: const TextStyle(fontSize: 10, color: Colors.white24)),
        trailing: const Icon(IconsaxPlusLinear.arrow_right_3, size: 14, color: Colors.white10),
      )),
    );
  }

  Widget _buildToggles() {
    return Column(
      children: [
        _toggleItem("Maintenance Mode", false),
        _toggleItem("Allow New Signups", true),
        _toggleItem("Force App Update", false),
        _toggleItem("Show Notice Board", true),
      ],
    );
  }

  Widget _toggleItem(String label, bool initial) {
    bool val = initial;
    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: val,
                onChanged: (v) => setState(() => val = v),
                activeColor: AdminTheme.accent,
              ),
            ),
          ],
        ),
      );
    });
  }
}
