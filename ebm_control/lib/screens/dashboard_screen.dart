import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../widgets/glass_box.dart';
import '../widgets/control_core.dart';
import '../core/clipboard_helper.dart';
import 'super_audit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _activeFilter = "ALL USERS";
  bool _isSidebarPinned = true;
  bool _isSidebarHovering = false;
  
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

  void _showInvitationDialog() {
    String selectedRole = "USERS";
    final TextEditingController emailC = TextEditingController();
    bool isGenerating = false;
    String? invitationLink;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111).withOpacity(0.8) : Colors.white.withOpacity(0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AdminTheme.accent.withOpacity(0.2))),
          title: Text(invitationLink == null ? "GENERATE SECURITY INVITATION" : "INVITATION READY", 
            style: const TextStyle(color: AdminTheme.accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (invitationLink == null) ...[
                const Text("Create a one-time secure join link for a new member.", style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 20),
                _buildDialogField(emailC, "Invited Email Address", IconsaxPlusLinear.sms),
                const SizedBox(height: 20),
                const Text("Authority Level", style: TextStyle(color: Colors.white24, fontSize: 10)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["SUPER ADMIN", "ADMIN", "USERS"].map((role) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(role, style: const TextStyle(fontSize: 10)),
                        selected: selectedRole == role,
                        onSelected: (val) => setDialogState(() => selectedRole = role),
                        selectedColor: AdminTheme.accent,
                        labelStyle: TextStyle(color: selectedRole == role ? Colors.black : Colors.white24),
                        backgroundColor: Colors.black,
                        side: BorderSide(color: selectedRole == role ? AdminTheme.accent : Colors.white10),
                      ),
                    )).toList(),
                  ),
                ),
              ] else ...[
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withOpacity(0.2))),
                   child: Column(
                     children: [
                       const Icon(IconsaxPlusBold.link_2, color: Colors.greenAccent, size: 32),
                       const SizedBox(height: 12),
                       const Text("Secure link generated successfully for:", style: TextStyle(color: Colors.white38, fontSize: 11)),
                       Text(emailC.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(8)),
                         child: SelectableText(invitationLink!, style: const TextStyle(color: AdminTheme.accent, fontSize: 10, fontFamily: 'monospace')),
                       ),
                     ],
                   ),
                 ),
              ],
            ],
          ),
          actions: [
            if (invitationLink == null) ...[
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24, fontSize: 12))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (emailC.text.contains("@")) {
                    setDialogState(() => isGenerating = true);
                    Future.delayed(const Duration(seconds: 1), () {
                      setDialogState(() {
                        isGenerating = false;
                        invitationLink = "https://ebfic.store/join?token=${Random().nextInt(999999)}secret";
                      });
                    });
                  }
                },
                child: isGenerating ? const SizedBox(height:12, width:12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text("GENERATE LINK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                onPressed: () async {
                  await ClipboardHelper.copy(context, invitationLink!);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("COPY & CLOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ],
        ),
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
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool isDesktop = screenWidth > 1024;
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final Color bgColor = Theme.of(context).scaffoldBackgroundColor;

      return Scaffold(
        backgroundColor: bgColor,
        // Drawer for Mobile/Tablet only
        drawer: !isDesktop ? Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _buildSidebar(context, isDrawer: true),
        ) : null,
        body: Stack(
          children: [
            // Background Gradients
            Positioned(
              top: -200, left: -200,
              child: Container(
                width: 600, height: 600,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AdminTheme.accent.withOpacity(isDark ? 0.05 : 0.08)),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container()),
              ),
            ),
            Row(
              children: [
                if (isDesktop) _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, !isDesktop),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isDesktop ? 32 : 16),
                          child: _selectedIndex == 4
                            ? const SuperAuditScreen()
                            : _selectedIndex == 1 
                              ? _buildPowerUserPanel(context) 
                              : _buildMainOverview(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

  Widget _buildMainOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatGrid(context),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _contentBox(context, "REAL-TIME LOGS", _buildLogList(context))),
            const SizedBox(width: 24),
            SizedBox(width: 350, child: _contentBox(context, "CENTRAL TOGGLES", _buildToggles(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerUserPanel(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredUsers = _activeFilter == "ALL USERS" 
        ? _users 
        : _users.where((u) => u['role'] == _activeFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Global Entity Hub", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1.5)),
                const SizedBox(height: 4),
                Text("Unified Access Control Management", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
            const Spacer(),
            _buildSmallStatBox(context, "TOTAL NODES", "${_users.length}", AdminTheme.accent),
            const SizedBox(width: 16),
            _buildSmallStatBox(context, "ACTIVE SYNC", "432", Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: GlassBox(
                blur: 15,
                opacity: isDark ? 0.03 : 0.8,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  children: [
                    Icon(IconsaxPlusLinear.search_status, color: isDark ? Colors.white38 : Colors.black38, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(hintText: "Search Identites...", hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black38), border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            _primaryActionButton(context, "Issue Invitation Link", IconsaxPlusLinear.key, onTap: _showInvitationDialog),
          ],
        ),
        const SizedBox(height: 48),
        _contentBox(context, "Authorized Security Directory", Column(
          children: [
            _userTableHeader(context),
            Divider(color: AdminTheme.glassBorder(context), height: 1),
            const SizedBox(height: 8),
            ...filteredUsers.map((u) => _userTableRow(context, u['name'], u['id'], u['email'], u['role'], u['color'], u['online'])),
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

  Widget _buildSmallStatBox(BuildContext context, String label, String value, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      blur: 10,
      borderRadius: 16,
      opacity: isDark ? 0.05 : 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)])),
               const SizedBox(width: 8),
               Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _userTableHeader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerColor = isDark ? Colors.white38 : Colors.black38;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text("IDENTITY PROFILE", style: TextStyle(color: headerColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text("COMMUNICATION", style: TextStyle(color: headerColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text("SECURITY LEVEL", style: TextStyle(color: headerColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text("MGMT", textAlign: TextAlign.right, style: TextStyle(color: headerColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _userTableRow(BuildContext context, String name, String id, String email, String role, Color roleColor, bool isOnline) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    String idPrefix = role == "SUPER ADMIN" ? "SID" : (role == "ADMIN" ? "AID" : "UID");
    String fullID = "$idPrefix-$id";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)))),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: roleColor.withOpacity(0.15), child: Text(name[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 18))),
                    if (isOnline) Positioned(right: 0, bottom: 0, child: Container(height: 12, width: 12, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF0D0B14) : Colors.white, width: 2)))),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    _idBadge(id, roleColor),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(email, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black54))),
          Expanded(flex: 2, child: _roleBadge(role, roleColor)),
          Expanded(
            flex: 2, 
            child: Row(
              children: [
                Icon(IconsaxPlusBold.shield_security, color: isOnline ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black26), size: 16),
                const SizedBox(width: 8),
                Text(isOnline ? "BOUND" : "UNBOUND", style: TextStyle(color: isOnline ? (isDark ? Colors.white70 : Colors.black54) : (isDark ? Colors.white38 : Colors.black38), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconAction(context, IconsaxPlusLinear.security_user, AdminTheme.accent),
              const SizedBox(width: 12),
              _iconAction(context, IconsaxPlusLinear.trash, Colors.redAccent),
            ],
          )),
        ],
      ),
    );
  }

  Widget _idBadge(String id, Color color) {
    return GestureDetector(
      onTap: () => ClipboardHelper.copy(context, id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(id, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _iconAction(BuildContext context, IconData icon, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.1 : 0.15), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _primaryActionButton(BuildContext context, String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AdminTheme.accent, AdminTheme.accent.withOpacity(0.8)]), 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AdminTheme.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(children: [Icon(icon, size: 20, color: Colors.black87), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 14))]),
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

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isExpanded = isDrawer || _isSidebarPinned || _isSidebarHovering;
    const double maxExpandedWidth = 280.0;
    const double collapsedWidth = 90.0;
    final double sidebarWidth = isExpanded ? maxExpandedWidth : collapsedWidth;
    final Color bgColor = isDark ? const Color(0xFF0A090E) : const Color(0xFFF9F9FB);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    Widget sidebarContent = AnimatedContainer(
      duration: 350.ms,
      curve: Curves.fastOutSlowIn,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: !isDrawer ? Border(right: BorderSide(color: borderColor, width: 1)) : null,
        boxShadow: !isDrawer && !_isSidebarPinned && isExpanded ? [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 40, offset: const Offset(15, 0))
        ] : [],
      ),
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: isExpanded ? 20 : 16),
      child: Column(
        children: [
          // Premium Header
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                const ControlCore(size: 36),
                if (isExpanded) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text("CONTROL-X", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 15, color: textColor)),
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                  if (!isDrawer)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _isSidebarPinned = !_isSidebarPinned;
                        if (!_isSidebarPinned) _isSidebarHovering = true; // Keep open smoothly while mouse is still there
                      }),
                      child: Tooltip(
                        message: _isSidebarPinned ? "Unpin Menu" : "Pin Menu",
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSidebarPinned ? AdminTheme.accent.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isSidebarPinned ? IconsaxPlusBold.lock_1 : IconsaxPlusLinear.unlock, 
                            size: 18, 
                            color: _isSidebarPinned ? AdminTheme.accent : (isDark ? Colors.white38 : Colors.black38)
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 48),
          _sidebarItem(context, IconsaxPlusLinear.element_3, "Dashboard", 0, isExpanded, isDrawer: isDrawer),
          _sidebarItem(context, IconsaxPlusLinear.profile_2user, "Identities", 1, isExpanded, isDrawer: isDrawer),
          _sidebarItem(context, IconsaxPlusLinear.monitor, "Monitoring", 2, isExpanded, isDrawer: isDrawer),
          _sidebarItem(context, IconsaxPlusLinear.shield_security, "Super Audit", 4, isExpanded, isDrawer: isDrawer, color: Colors.redAccent.withOpacity(0.85)),
          _sidebarItem(context, IconsaxPlusLinear.setting_2, "Network Hub", 3, isExpanded, isDrawer: isDrawer),
          const Spacer(),
          
          if (isExpanded)
            GlassBox(
              blur: 10,
              opacity: isDark ? 0.03 : 0.3,
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                   Container(
                     height: 42, width: 42, 
                     decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AdminTheme.accent, AdminTheme.accent.withOpacity(0.6)])), 
                     child: const Center(child: Text("A", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))
                   ),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start, 
                       children: [
                         Text("Atikur", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)), 
                         const SizedBox(height: 3), 
                         Text("SUPER ADMIN", style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 1.2))
                       ]
                     )
                   ),
                ],
              ),
            ).animate().fadeIn()
          else
             Container(
               height: 46, width: 46, 
               decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AdminTheme.accent.withOpacity(0.3), width: 2)), 
               child: const Center(child: Text("A", style: TextStyle(color: AdminTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)))
             ),
          const SizedBox(height: 16),
          _sidebarItem(context, IconsaxPlusLinear.logout, "Terminate", 99, isExpanded, isDrawer: isDrawer, color: Colors.redAccent),
        ],
      ),
    );

    if (isDrawer) return sidebarContent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarHovering = true),
      onExit: (_) => setState(() => _isSidebarHovering = false),
      child: sidebarContent,
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, int index, bool isExpanded, {bool isDrawer = false, Color? color}) {
    bool isSelected = _selectedIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color itemColor = color ?? (isDark ? Colors.white70 : Colors.black87);
    final Color selectedItemColor = color ?? AdminTheme.accent;
    final Color unselectedIconColor = color ?? (isDark ? Colors.white38 : Colors.black38);
    
    return GestureDetector(
      onTap: () {
        if (label == "Terminate") {
          context.go('/sp-login');
          return;
        }
        setState(() => _selectedIndex = index);
        if (isDrawer) Navigator.pop(context); // Close drawer on selection
      },
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOutCirc,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 0, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedItemColor.withOpacity(isDark ? 0.12 : 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? selectedItemColor.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? selectedItemColor : unselectedIconColor, 
              size: 22 
            ),
            if (isExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? selectedItemColor : itemColor, 
                    fontSize: 13, 
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )
                ).animate().fadeIn(duration: 200.ms),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool showMenu) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)))),
      child: Row(
        children: [
          if (showMenu)
            Builder(builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(IconsaxPlusLinear.menu_1, color: AdminTheme.accent, size: 28),
              ),
            )),
          if (showMenu) const SizedBox(width: 16),
          Row(
            children: [
              Icon(IconsaxPlusBold.shield_search, color: AdminTheme.accent, size: 28),
              const SizedBox(width: 16),
              Text("CONTROL-X", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15, color: textColor)),
            ],
          ),
          const Spacer(),
          if (!showMenu) _statusChip(context, "MESH ONLINE", Colors.greenAccent),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () {
              AdminTheme.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
            child: _premiumActionIcon(context, isDark ? IconsaxPlusLinear.sun_1 : IconsaxPlusLinear.moon),
          ),
          const SizedBox(width: 16),
          _premiumActionIcon(context, IconsaxPlusLinear.notification),
        ],
      ),
    );
  }

  Widget _premiumActionIcon(BuildContext context, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      blur: 10,
      borderRadius: 14,
      opacity: isDark ? 0.05 : 0.2,
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black87),
    );
  }

  Widget _statusChip(BuildContext context, String label, Color color) {
    return GlassBox(
      blur: 2,
      borderRadius: 20,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(height: 6, width: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)])),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _statCard(context, "Android Activity", "12,840", Icons.android_rounded, Colors.greenAccent),
        _statCard(context, "Windows Nodes", "4,210", Icons.window_rounded, AdminTheme.accent),
        _statCard(context, "Identity Syncs", "8,922", IconsaxPlusBold.user_tag, Colors.orangeAccent),
        _statCard(context, "System Mesh", "v2.0.4", IconsaxPlusBold.cpu, Colors.purpleAccent),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, String val, IconData icon, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      blur: 20,
      opacity: isDark ? 0.04 : 0.5,
      borderRadius: 24,
      padding: const EdgeInsets.all(28),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color)
              ), 
              const SizedBox(width: 16), 
              Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)))
            ]),
            const SizedBox(height: 24),
            Text(val, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _contentBox(BuildContext context, String title, Widget content) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      blur: 25,
      opacity: isDark ? 0.03 : 0.6,
      borderRadius: 24,
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: AdminTheme.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.grey : Colors.black54)),
            ],
          ),
          const SizedBox(height: 32), 
          content
        ]
      ),
    );
  }

  Widget _buildLogList(BuildContext context) {
    return Column(
      children: List.generate(5, (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
             Container(height: 32, width: 4, decoration: BoxDecoration(color: AdminTheme.accent, borderRadius: BorderRadius.circular(2))),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("SECURE TUNNEL ESTABLISHED: NODE #00${index + 71}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Protocol: AES-GCM-256 | Latency: 12ms", style: TextStyle(fontSize: 10, color: Colors.grey)),
                 ],
               ),
             ),
          ],
        ),
      )),
    );
  }

  Widget _buildToggles(BuildContext context) {
    return Column(children: [_toggleItem("Global Lockdown", false), _toggleItem("External Hub Access", true), _toggleItem("Automatic Identity Expire", true)]);
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
