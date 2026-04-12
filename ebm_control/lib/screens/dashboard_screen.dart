import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _activeFilter = "ALL USERS";
  
  // Mock User Database
  final List<Map<String, dynamic>> _users = [
    {"name": "Atikur Rahman", "id": "313786241786", "email": "atik@ebfic.com", "role": "SUPER ADMIN", "color": Colors.amber, "online": true},
    {"name": "Sabbir Ahammed", "id": "786313025021", "email": "sabbir@ebfic.com", "role": "ADMIN", "color": Colors.blueAccent, "online": true},
    {"name": "John Doe", "id": "313687521110", "email": "john@example.com", "role": "USERS", "color": Colors.greenAccent, "online": false},
  ];

  // অটো-আইডি জেনারেশন লজিক
  String _generateUniqueId(String role) {
    String prefix = "";
    if (role == "SUPER ADMIN") prefix = "313786";
    else if (role == "ADMIN") prefix = "786313";
    else prefix = "313687";
    
    // বাকি ৬ ডিজিট র্যান্ডমলি জেনারেট করা
    var random = Random();
    String suffix = "";
    for (var i = 0; i < 6; i++) {
       suffix += random.nextInt(10).toString();
    }
    return prefix + suffix;
  }

  void _showAddUserDialog() {
    String selectedRole = "USERS";
    final TextEditingController nameC = TextEditingController();
    final TextEditingController emailC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text("CREATE NEW IDENTITY", style: TextStyle(color: AdminTheme.accent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameC, "Full Name", IconsaxPlusLinear.user),
              const SizedBox(height: 16),
              _buildDialogField(emailC, "Email Address", IconsaxPlusLinear.sms),
              const SizedBox(height: 24),
              const Text("Select Authority Level", style: TextStyle(color: Colors.white24, fontSize: 10)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["SUPER ADMIN", "ADMIN", "USERS"].map((role) => ChoiceChip(
                  label: Text(role, style: const TextStyle(fontSize: 10)),
                  selected: selectedRole == role,
                  onSelected: (val) => setDialogState(() => selectedRole = role),
                  selectedColor: AdminTheme.accent,
                  labelStyle: TextStyle(color: selectedRole == role ? Colors.black : Colors.white24),
                  backgroundColor: Colors.black,
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accent, foregroundColor: Colors.black),
              onPressed: () {
                if (nameC.text.isNotEmpty && emailC.text.contains("@")) {
                  setState(() {
                    _users.add({
                      "name": nameC.text,
                      "email": emailC.text,
                      "id": _generateUniqueId(selectedRole),
                      "role": selectedRole,
                      "color": selectedRole == "SUPER ADMIN" ? Colors.amber : (selectedRole == "ADMIN" ? Colors.blueAccent : Colors.greenAccent),
                      "online": false
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("GENERATE IDENTITY"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AdminTheme.accent, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _selectedIndex == 1 
                      ? _buildPowerUserPanel() 
                      : _buildMainOverview(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatGrid(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _contentBox("Real-time System Activity", _buildLogList())),
            const SizedBox(width: 24),
            SizedBox(width: 350, child: _contentBox("Quick Control Toggles", _buildToggles())),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerUserPanel() {
    final filteredUsers = _activeFilter == "ALL USERS" 
        ? _users 
        : _users.where((u) => u['role'] == _activeFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("User Ecosystem", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const Spacer(),
            _buildSmallStatBox("TOTAL USERS", "${_users.length}", Colors.blueAccent),
            const SizedBox(width: 16),
            _buildSmallStatBox("ACTIVE NOW", "432", Colors.greenAccent),
            const SizedBox(width: 16),
            _buildSmallStatBox("ADMINS", "${_users.where((u) => u['role'] == 'ADMIN').length}", Colors.amberAccent),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Row(
                  children: [
                    const Icon(IconsaxPlusLinear.search_normal, color: Colors.white24, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(hintText: "Search Identites...", hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            _filterActionButton("Export", IconsaxPlusLinear.document_download),
            const SizedBox(width: 12),
            _primaryActionButton("Add Identity", IconsaxPlusLinear.user_add, onTap: _showAddUserDialog),
          ],
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterTab("ALL USERS"),
              _filterTab("SUPER ADMIN"),
              _filterTab("ADMIN"),
              _filterTab("USERS"),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _contentBox("Authorized Entity Directory", Column(
          children: [
            _userTableHeader(),
            const Divider(color: Colors.white10, height: 1),
            ...filteredUsers.map((u) => _userTableRow(u['name'], u['id'], u['email'], u['role'], u['color'], u['online'])),
          ],
        )),
      ],
    );
  }

  Widget _filterTab(String label) {
    bool active = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: active ? AdminTheme.accent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? AdminTheme.accent : Colors.white10)),
        child: Text(label, style: TextStyle(color: active ? AdminTheme.accent : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSmallStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _userTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.white.withOpacity(0.01),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text("IDENTITY PROFILE", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
          Expanded(flex: 3, child: Text("COMMUNICATION", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
          Expanded(flex: 2, child: Text("SECURITY LEVEL", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
          Expanded(flex: 1, child: Text("MGMT", textAlign: TextAlign.right, style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        ],
      ),
    );
  }

  Widget _userTableRow(String name, String id, String email, String role, Color roleColor, bool isOnline) {
    String idPrefix = role == "SUPER ADMIN" ? "SID" : (role == "ADMIN" ? "AID" : "UID");
    String fullID = "$idPrefix-$id";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 18, backgroundColor: roleColor.withOpacity(0.1), child: Text(name[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.bold))),
                    if (isOnline) Positioned(right: 0, bottom: 0, child: Container(height: 10, width: 10, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)))),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _idBadge(id, roleColor),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(email, style: const TextStyle(fontSize: 12, color: Colors.white38))),
          Expanded(flex: 2, child: _roleBadge(role, roleColor)),
          Expanded(flex: 1, child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconAction(IconsaxPlusLinear.edit, AdminTheme.accent),
              const SizedBox(width: 12),
              _iconAction(IconsaxPlusLinear.trash, Colors.redAccent),
            ],
          )),
        ],
      ),
    );
  }

  Widget _idBadge(String id, Color color) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ID: $id Copied!"), backgroundColor: AdminTheme.accent, behavior: SnackBarBehavior.floating, width: 200, duration: const Duration(seconds: 1)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(id, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: color.withOpacity(0.7)),
    );
  }

  Widget _primaryActionButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AdminTheme.accent, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Icon(icon, size: 16, color: Colors.black), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
    );
  }

  Widget _filterActionButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(children: [Icon(icon, size: 16, color: Colors.white54), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
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
          _sidebarItem(IconsaxPlusLinear.profile_2user, 1),
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
        child: Icon(icon, color: isSelected ? AdminTheme.accent : (color ?? Colors.white38), size: 24),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        children: [
          const Text("EBFIC CONTROL CENTER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16, color: AdminTheme.textDim)),
          const Spacer(),
          _statusChip("SYSTEM LIVE", Colors.greenAccent),
          const SizedBox(width: 16),
          const CircleAvatar(radius: 18, backgroundColor: AdminTheme.surface, child: Icon(IconsaxPlusLinear.user, size: 18, color: AdminTheme.accent)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
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
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.cardRadius), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12))]),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _contentBox(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54)), const SizedBox(height: 24), content]),
    );
  }

  Widget _buildLogList() {
    return Column(
      children: List.generate(5, (index) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(radius: 4, backgroundColor: AdminTheme.accent),
        title: Text("Authorized system access granted to ID #$index", style: const TextStyle(fontSize: 12)),
        subtitle: Text("Network Latency: 24ms", style: const TextStyle(fontSize: 10, color: Colors.white24)),
      )),
    );
  }

  Widget _buildToggles() {
    return Column(children: [_toggleItem("Global Maintenance", false), _toggleItem("External Signups", true), _toggleItem("System-wide Forced Update", false)]);
  }

  Widget _toggleItem(String label, bool initial) {
    bool val = initial;
    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)), Transform.scale(scale: 0.8, child: Switch(value: val, onChanged: (v) => setState(() => val = v), activeColor: AdminTheme.accent))]),
      );
    });
  }
}
