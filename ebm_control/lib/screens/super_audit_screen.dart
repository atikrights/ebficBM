import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../core/theme.dart';
import '../widgets/glass_box.dart';

class SuperAuditScreen extends StatefulWidget {
  const SuperAuditScreen({super.key});

  @override
  State<SuperAuditScreen> createState() => _SuperAuditScreenState();
}

class _SuperAuditScreenState extends State<SuperAuditScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = "ALL";
  String _searchQuery = "";

  // ─── Mock Audit Data ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _loginAttempts = [
    {
      "id": "ATT-001",
      "email": "admin@ebfic.store",
      "status": "SUCCESS",
      "ip": "103.85.24.112",
      "country": "Bangladesh",
      "city": "Dhaka",
      "device": "Chrome 124 / Windows 11",
      "extension": true,
      "method": "VAULT_AUTOFILL",
      "time": "2026-04-19 15:02:11",
      "attempts": 1,
    },
    {
      "id": "ATT-002",
      "email": "admin@ebfic.store",
      "status": "FAILED",
      "ip": "185.220.101.45",
      "country": "Germany",
      "city": "Frankfurt",
      "device": "Firefox 125 / Linux",
      "extension": false,
      "method": "MANUAL",
      "time": "2026-04-19 14:48:33",
      "attempts": 3,
    },
    {
      "id": "ATT-003",
      "email": "admin@ebfic.store",
      "status": "BLOCKED",
      "ip": "45.142.212.100",
      "country": "Russia",
      "city": "Moscow",
      "device": "Unknown / Unknown",
      "extension": false,
      "method": "BRUTE_FORCE",
      "time": "2026-04-19 14:22:07",
      "attempts": 10,
    },
    {
      "id": "ATT-004",
      "email": "admin@ebfic.store",
      "status": "SUCCESS",
      "ip": "103.85.24.112",
      "country": "Bangladesh",
      "city": "Dhaka",
      "device": "Chrome 124 / Windows 11",
      "extension": true,
      "method": "VAULT_AUTOFILL",
      "time": "2026-04-19 09:11:55",
      "attempts": 1,
    },
    {
      "id": "ATT-005",
      "email": "admin@ebfic.store",
      "status": "FAILED",
      "ip": "91.108.4.120",
      "country": "Netherlands",
      "city": "Amsterdam",
      "device": "cURL / Unknown",
      "extension": false,
      "method": "MANUAL",
      "time": "2026-04-18 22:14:39",
      "attempts": 2,
    },
    {
      "id": "ATT-006",
      "email": "admin@ebfic.store",
      "status": "SUCCESS",
      "ip": "103.85.24.112",
      "country": "Bangladesh",
      "city": "Dhaka",
      "device": "Edge 124 / Windows 11",
      "extension": false,
      "method": "MANUAL",
      "time": "2026-04-18 11:05:20",
      "attempts": 1,
    },
    {
      "id": "ATT-007",
      "email": "admin@ebfic.store",
      "status": "BLOCKED",
      "ip": "198.199.77.133",
      "country": "United States",
      "city": "New York",
      "device": "Python Requests / Linux",
      "extension": false,
      "method": "BRUTE_FORCE",
      "time": "2026-04-17 18:33:11",
      "attempts": 15,
    },
  ];

  final List<Map<String, dynamic>> _activeSessions = [
    {
      "sessionId": "SID-F3A79C",
      "ip": "103.85.24.112",
      "device": "Chrome 124 / Windows 11",
      "country": "Bangladesh 🇧🇩",
      "loginTime": "2026-04-19 15:02:11",
      "vaultConnected": true,
      "duration": "13 minutes",
      "status": "ACTIVE",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Status Color & Icon ─────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case "SUCCESS": return Colors.greenAccent;
      case "FAILED": return Colors.orangeAccent;
      case "BLOCKED": return Colors.redAccent;
      default: return Colors.white38;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "SUCCESS": return IconsaxPlusBold.shield_tick;
      case "FAILED": return IconsaxPlusBold.shield_cross;
      case "BLOCKED": return IconsaxPlusBold.slash;
      default: return Icons.help_outline;
    }
  }

  List<Map<String, dynamic>> get _filteredAttempts {
    return _loginAttempts.where((a) {
      final matchStatus = _filterStatus == "ALL" || a['status'] == _filterStatus;
      final matchSearch = _searchQuery.isEmpty ||
          a['ip'].toString().contains(_searchQuery) ||
          a['device'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a['country'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a['method'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
  }

  // ─── Summary Stats ───────────────────────────────────────────────────────────
  int get _totalSuccess => _loginAttempts.where((a) => a['status'] == "SUCCESS").length;
  int get _totalFailed => _loginAttempts.where((a) => a['status'] == "FAILED").length;
  int get _totalBlocked => _loginAttempts.where((a) => a['status'] == "BLOCKED").length;
  int get _vaultLogins => _loginAttempts.where((a) => a['extension'] == true).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Page Header ─────────────────────────────────────────────────────
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Super Audit",
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "COMPLETE SECURITY INTELLIGENCE & ACCESS HISTORY",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildActionButton(
              context,
              "EXPORT LOGS",
              IconsaxPlusLinear.document_download,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Exporting audit logs... (CSV)"),
                    backgroundColor: Colors.greenAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 32),

        // ─── Stat Summary Cards ───────────────────────────────────────────────
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _statCard(context, "SUCCESSFUL LOGINS", "$_totalSuccess",
                IconsaxPlusBold.shield_tick, Colors.greenAccent, "+2 today"),
            _statCard(context, "FAILED ATTEMPTS", "$_totalFailed",
                IconsaxPlusBold.shield_cross, Colors.orangeAccent, "From 2 IPs"),
            _statCard(context, "BLOCKED (BRUTE FORCE)", "$_totalBlocked",
                IconsaxPlusBold.slash, Colors.redAccent, "⚠️ Suspicious"),
            _statCard(context, "VAULT AUTOFILL LOGINS", "$_vaultLogins",
                IconsaxPlusBold.shield_security, AdminTheme.accent, "Extension synced"),
          ],
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 32),

        // ─── Tab Bar ─────────────────────────────────────────────────────────
        GlassBox(
          blur: 20,
          opacity: isDark ? 0.03 : 0.5,
          borderRadius: 24,
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 16,
                      decoration: BoxDecoration(
                        color: AdminTheme.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AdminTheme.accent,
                      labelColor: AdminTheme.accent,
                      unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "LOGIN ATTEMPTS"),
                        Tab(text: "ACTIVE SESSIONS"),
                        Tab(text: "THREAT MAP"),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter + Search bar for login attempts tab
              ValueListenableBuilder(
                valueListenable: _tabController.animation!,
                builder: (_, val, __) {
                  final isFirst = _tabController.index == 0;
                  if (!isFirst) return const SizedBox.shrink();
                  return _buildFilterBar(context, isDark);
                },
              ),

              Divider(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                height: 1,
              ),

              // Tab views
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginAttemptsTab(context, isDark),
                    _buildActiveSessionsTab(context, isDark),
                    _buildThreatMapTab(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: GlassBox(
              blur: 10,
              opacity: isDark ? 0.05 : 0.6,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(IconsaxPlusLinear.search_status,
                      color: isDark ? Colors.white38 : Colors.black38, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(
                          fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Search IP, device, country, method...",
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status filters
          ...["ALL", "SUCCESS", "FAILED", "BLOCKED"].map((f) => _filterChip(f, isDark)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isDark) {
    final isActive = _filterStatus == label;
    final color = label == "SUCCESS"
        ? Colors.greenAccent
        : label == "FAILED"
            ? Colors.orangeAccent
            : label == "BLOCKED"
                ? Colors.redAccent
                : AdminTheme.accent;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = label),
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Text(label,
            style: TextStyle(
              color: isActive ? color : (isDark ? Colors.white38 : Colors.black38),
              fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1,
            )),
      ),
    );
  }

  // ─── Login Attempts Tab ───────────────────────────────────────────────────────
  Widget _buildLoginAttemptsTab(BuildContext context, bool isDark) {
    final filtered = _filteredAttempts;
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        // Table header
        _tableHeader(context, isDark),
        const Divider(height: 1, color: Colors.white10),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text("No records match your filter.",
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
            ),
          ),
        ...filtered.map((a) => _attemptRow(context, a, isDark)),
      ],
    );
  }

  Widget _tableHeader(BuildContext context, bool isDark) {
    final headerColor = isDark ? Colors.white24 : Colors.black38;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("STATUS", style: _headerStyle(headerColor))),
          Expanded(flex: 3, child: Text("IP & LOCATION", style: _headerStyle(headerColor))),
          Expanded(flex: 3, child: Text("DEVICE / BROWSER", style: _headerStyle(headerColor))),
          Expanded(flex: 2, child: Text("METHOD", style: _headerStyle(headerColor))),
          Expanded(flex: 2, child: Text("TIME", style: _headerStyle(headerColor))),
          SizedBox(width: 60, child: Text("INFO", textAlign: TextAlign.right, style: _headerStyle(headerColor))),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color c) =>
      TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2);

  Widget _attemptRow(BuildContext context, Map<String, dynamic> a, bool isDark) {
    final color = _statusColor(a['status']);
    return GestureDetector(
      onTap: () => _showAttemptDetails(context, a, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04),
          )),
        ),
        child: Row(
          children: [
            // Status
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(a['status']), color: color, size: 12),
                        const SizedBox(width: 6),
                        Text(a['status'],
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // IP & Location
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconsaxPlusLinear.global, color: isDark ? Colors.white54 : Colors.black54, size: 14),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: a['ip']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("IP Copied: ${a['ip']}"),
                              backgroundColor: AdminTheme.accent,
                              behavior: SnackBarBehavior.floating, width: 220,
                              duration: const Duration(seconds: 1)),
                          );
                        },
                        child: Text(a['ip'],
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("${a['city']}, ${a['country']}",
                      style: TextStyle(
                          fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ),
            // Device
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(
                    a['device'].toString().contains('Mobile') ? Icons.phone_android_rounded : Icons.computer_rounded,
                    size: 14, color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a['device'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                  ),
                  if (a['extension'] == true) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Logged in via EBM Identity Vault",
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AdminTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminTheme.accent.withOpacity(0.3)),
                        ),
                        child: const Text("VAULT", style: TextStyle(color: AdminTheme.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Method
            Expanded(
              flex: 2,
              child: Text(a['method'].toString().replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: a['method'] == 'BRUTE_FORCE'
                          ? Colors.redAccent
                          : (isDark ? Colors.white54 : Colors.black54))),
            ),
            // Time
            Expanded(
              flex: 2,
              child: Text(a['time'],
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            ),
            // Info button
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if ((a['attempts'] as int) > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("×${a['attempts']}",
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  Icon(IconsaxPlusLinear.info_circle,
                      size: 18, color: isDark ? Colors.white24 : Colors.black26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttemptDetails(BuildContext context, Map<String, dynamic> a, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF0F0E14).withOpacity(0.98) : Colors.white.withOpacity(0.98),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: _statusColor(a['status']).withOpacity(0.3))),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          contentPadding: const EdgeInsets.all(28),
          title: Row(
            children: [
              Icon(_statusIcon(a['status']), color: _statusColor(a['status']), size: 22),
              const SizedBox(width: 12),
              Text("Access Attempt ${a['id']}",
                  style: TextStyle(
                      color: _statusColor(a['status']),
                      fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(isDark, "Email", a['email'], icon: IconsaxPlusLinear.sms),
                _detailRow(isDark, "IP Address", a['ip'], icon: IconsaxPlusLinear.global, copyable: true, context: context),
                _detailRow(isDark, "Location", "${a['city']}, ${a['country']}", icon: IconsaxPlusLinear.location),
                _detailRow(isDark, "Device", a['device'], icon: Icons.computer_rounded),
                _detailRow(isDark, "Login Method", a['method'].toString().replaceAll('_', ' '),
                    icon: IconsaxPlusLinear.key),
                _detailRow(isDark, "Attempts Count", "${a['attempts']}x",
                    icon: Icons.repeat_rounded,
                    dangerColor: (a['attempts'] as int) > 1 ? Colors.redAccent : null),
                _detailRow(isDark, "Vault Extension", a['extension'] == true ? "YES — EBM Vault Synced" : "NO — Manual Entry",
                    icon: IconsaxPlusLinear.shield_security,
                    accentColor: a['extension'] == true ? AdminTheme.accent : null),
                _detailRow(isDark, "Timestamp", a['time'], icon: IconsaxPlusLinear.clock),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            if (a['status'] == 'BLOCKED' || (a['attempts'] as int) >= 3)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("IP ${a['ip']} has been permanently blacklisted."),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.block_rounded, size: 16),
                label: const Text("BLACKLIST IP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value, {
    IconData? icon,
    bool copyable = false,
    BuildContext? context,
    Color? dangerColor,
    Color? accentColor,
  }) {
    final valueColor = dangerColor ?? accentColor ?? (isDark ? Colors.white : Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 16, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable && context != null
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Copied: $value"),
                          backgroundColor: AdminTheme.accent,
                          behavior: SnackBarBehavior.floating,
                          width: 200, duration: const Duration(seconds: 1)),
                      );
                    }
                  : null,
              child: Text(value,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: valueColor,
                    decoration: copyable ? TextDecoration.underline : TextDecoration.none,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active Sessions Tab ─────────────────────────────────────────────────────
  Widget _buildActiveSessionsTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_activeSessions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  Icon(IconsaxPlusLinear.shield_cross,
                      size: 48, color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 16),
                  Text("No active sessions",
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ),
          ),
        ..._activeSessions.map((s) => _sessionCard(context, s, isDark)),
      ],
    );
  }

  Widget _sessionCard(BuildContext context, Map<String, dynamic> s, bool isDark) {
    return GlassBox(
      blur: 10,
      opacity: isDark ? 0.05 : 0.4,
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text("ACTIVE SESSION",
                        style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              if (s['vaultConnected'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminTheme.accent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(IconsaxPlusBold.shield_security, color: AdminTheme.accent, size: 14),
                      SizedBox(width: 6),
                      Text("VAULT CONNECTED",
                          style: TextStyle(color: AdminTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Session ${s['sessionId']} terminated."),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Text("TERMINATE",
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40, runSpacing: 16,
            children: [
              _infoField(isDark, "Session ID", s['sessionId'], icon: IconsaxPlusLinear.key),
              _infoField(isDark, "IP Address", s['ip'], icon: IconsaxPlusLinear.global),
              _infoField(isDark, "Device", s['device'], icon: Icons.computer_rounded),
              _infoField(isDark, "Location", s['country'], icon: IconsaxPlusLinear.location),
              _infoField(isDark, "Logged In At", s['loginTime'], icon: IconsaxPlusLinear.clock),
              _infoField(isDark, "Active For", s['duration'], icon: IconsaxPlusLinear.timer_1),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _infoField(bool isDark, String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 12, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  // ─── Threat Map Tab ──────────────────────────────────────────────────────────
  Widget _buildThreatMapTab(BuildContext context, bool isDark) {
    final threats = _loginAttempts.where((a) => a['status'] != 'SUCCESS').toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(IconsaxPlusBold.warning_2, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("THREAT INTELLIGENCE SUMMARY",
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      "${threats.length} suspicious access attempts detected from ${threats.map((t) => t['ip']).toSet().length} unique IPs.",
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...threats.map((t) => _threatRow(context, t, isDark)),
      ],
    );
  }

  Widget _threatRow(BuildContext context, Map<String, dynamic> t, bool isDark) {
    final color = _statusColor(t['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(t['status']), color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${t['ip']} — ${t['country']}",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text("${t['device']} | ${t['attempts']}x attempts | ${t['time']}",
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          _buildSmallTagButton(context, "BLOCK IP", Colors.redAccent),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSmallTagButton(BuildContext context, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Blocked. (Feature: API integration pending)"),
              backgroundColor: color, behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─── Stat Card ────────────────────────────────────────────────────────────────
  Widget _statCard(BuildContext context, String title, String val, IconData icon, Color color, String sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBox(
      blur: 20,
      opacity: isDark ? 0.04 : 0.5,
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
            ]),
            const SizedBox(height: 20),
            Text(val, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87, letterSpacing: -1)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey : Colors.black54, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(sub, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: AdminTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.accent.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AdminTheme.accent),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AdminTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
