import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/providers/theme_provider.dart';
import 'package:ebficbm/features/notifications/screens/notifications_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:ebficbm/core/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ebficbm/features/chat/presentation/chat_settings_screen.dart';
import 'package:ebficbm/features/chat/providers/chat_provider.dart';
import 'package:ebficbm/core/providers/td_set_provider.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;

  const ResponsiveLayout({
    super.key,
    required this.body,
    required this.title,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: (!isDesktop)
          ? Drawer(
              width: 280,
              backgroundColor: Theme.of(context).cardColor,
              child: _Sidebar(
                selectedIndex: selectedIndex,
                onNavigationChanged: (index) {
                  onNavigationChanged(index);
                  Navigator.pop(context);
                },
                isCollapsed: false,
              ),
            )
          : null,
      endDrawer: const NotificationsPanel(),
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              _Sidebar(
                selectedIndex: selectedIndex,
                onNavigationChanged: onNavigationChanged,
                isCollapsed: ResponsiveBreakpoints.of(context).isTablet,
              ),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AppBar(
                    title: title,
                    showMenu: !isDesktop,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;
  final bool isCollapsed;

  const _Sidebar({
    required this.selectedIndex,
    required this.onNavigationChanged,
    required this.isCollapsed,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  final Map<String, bool> _expandedGroups = {
    'Overview': true,
    'Workplace': true,
    'Chat': false,
  };

  void _toggleGroup(String key) {
    setState(() {
      _expandedGroups[key] = !(_expandedGroups[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = Provider.of<ChatProvider>(context);
    final unreadChatCount = chatProvider.totalUnreadCount;

    return Container(
      width: widget.isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _Logo(isCollapsed: widget.isCollapsed, isDark: isDark),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (!widget.isCollapsed) ...[
                  // --- OVERVIEW GROUP ---
                  _NavGroup(
                    label: 'Overview',
                    icon: Icons.home_rounded,
                    isCollapsed: widget.isCollapsed,
                    isExpanded: _expandedGroups['Overview'] ?? false,
                    onToggle: () => _toggleGroup('Overview'),
                    isSelected: widget.selectedIndex == 0 || widget.selectedIndex == 1,
                    children: [
                      _SubNavItem(
                        label: 'Dashboard',
                        icon: Icons.dashboard_rounded,
                        isSelected: widget.selectedIndex == 0,
                        onTap: () => widget.onNavigationChanged(0),
                        isNested: true,
                        isFirst: true,
                      ),
                      _SubNavItem(
                        label: 'Analysis',
                        icon: Icons.analytics_rounded,
                        isSelected: widget.selectedIndex == 1,
                        onTap: () => widget.onNavigationChanged(1),
                        isNested: true,
                        isLast: true,
                      ),
                    ],
                  ),

                  // --- WORKPLACE GROUP ---
                  _NavGroup(
                    label: 'Workplace',
                    icon: Icons.work_rounded,
                    isCollapsed: widget.isCollapsed,
                    isExpanded: _expandedGroups['Workplace'] ?? false,
                    onToggle: () => _toggleGroup('Workplace'),
                    isSelected: widget.selectedIndex >= 2 && widget.selectedIndex <= 6,
                    children: [
                      _SubNavItem(
                        label: 'Companies',
                        icon: Icons.business_rounded,
                        isSelected: widget.selectedIndex == 2,
                        onTap: () => widget.onNavigationChanged(2),
                        isNested: true,
                        isFirst: true,
                      ),
                      _SubNavItem(
                        label: 'Projects',
                        icon: Icons.assignment_rounded,
                        isSelected: widget.selectedIndex == 3,
                        onTap: () => widget.onNavigationChanged(3),
                        isNested: true,
                      ),
                      _SubNavItem(
                        label: 'Tasks',
                        icon: Icons.task_alt_rounded,
                        isSelected: widget.selectedIndex == 4,
                        onTap: () => widget.onNavigationChanged(4),
                        isNested: true,
                      ),
                      _SubNavItem(
                        label: 'Finance',
                        icon: Icons.payments_rounded,
                        isSelected: widget.selectedIndex == 5,
                        onTap: () => widget.onNavigationChanged(5),
                        isNested: true,
                      ),
                      _SubNavItem(
                        label: 'Reports',
                        icon: Icons.description_rounded,
                        isSelected: widget.selectedIndex == 6,
                        onTap: () => widget.onNavigationChanged(6),
                        isNested: true,
                        isLast: true,
                      ),
                    ],
                  ),

                  // --- CHAT GROUP ---
                  _NavGroup(
                    label: 'Chat',
                    icon: Icons.chat_bubble_rounded,
                    isCollapsed: widget.isCollapsed,
                    isExpanded: _expandedGroups['Chat'] ?? false,
                    onToggle: () {
                      _toggleGroup('Chat');
                      widget.onNavigationChanged(kIsWeb ? 15 : 16);
                    },
                    isSpecial: true,
                    isSelected: widget.selectedIndex == (kIsWeb ? 15 : 16) || widget.selectedIndex == 10 || widget.selectedIndex == 9,
                    badgeCount: unreadChatCount,
                    children: [
                      _SubNavItem(
                        label: 'All Chat',
                        icon: Icons.forum_rounded,
                        isSelected: widget.selectedIndex == 10,
                        onTap: () => widget.onNavigationChanged(10),
                        isNested: true,
                        isFirst: true,
                        badgeCount: unreadChatCount,
                      ),
                      _SubNavItem(
                        label: 'Broadcast',
                        icon: Icons.radar_rounded,
                        isSelected: widget.selectedIndex == 9,
                        onTap: () => widget.onNavigationChanged(9),
                        isNested: true,
                      ),
                      _SubNavItem(
                        label: 'Settings',
                        icon: Icons.settings_rounded,
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatSettingsScreen()),
                          );
                        },
                        isNested: true,
                        isLast: true,
                      ),
                    ],
                  ),
                ] else ...[
                  // --- COLLAPSED ICON NAVIGATION LIST ---
                  _SubNavItem(
                    label: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    isSelected: widget.selectedIndex == 0,
                    onTap: () => widget.onNavigationChanged(0),
                    isCollapsed: true,
                  ),
                  _SubNavItem(
                    label: 'Analysis',
                    icon: Icons.analytics_rounded,
                    isSelected: widget.selectedIndex == 1,
                    onTap: () => widget.onNavigationChanged(1),
                    isCollapsed: true,
                  ),
                  const SizedBox(height: 8),
                  _SubNavItem(
                    label: 'Companies',
                    icon: Icons.business_rounded,
                    isSelected: widget.selectedIndex == 2,
                    onTap: () => widget.onNavigationChanged(2),
                    isCollapsed: true,
                  ),
                  _SubNavItem(
                    label: 'Projects',
                    icon: Icons.assignment_rounded,
                    isSelected: widget.selectedIndex == 3,
                    onTap: () => widget.onNavigationChanged(3),
                    isCollapsed: true,
                  ),
                  _SubNavItem(
                    label: 'Tasks',
                    icon: Icons.task_alt_rounded,
                    isSelected: widget.selectedIndex == 4,
                    onTap: () => widget.onNavigationChanged(4),
                    isCollapsed: true,
                  ),
                  _SubNavItem(
                    label: 'Finance',
                    icon: Icons.payments_rounded,
                    isSelected: widget.selectedIndex == 5,
                    onTap: () => widget.onNavigationChanged(5),
                    isCollapsed: true,
                  ),
                  _SubNavItem(
                    label: 'Reports',
                    icon: Icons.description_rounded,
                    isSelected: widget.selectedIndex == 6,
                    onTap: () => widget.onNavigationChanged(6),
                    isCollapsed: true,
                  ),
                  const SizedBox(height: 8),
                  _SubNavItem(
                    label: 'Chat Dashboard',
                    icon: Icons.chat_bubble_rounded,
                    isSelected: widget.selectedIndex == (kIsWeb ? 15 : 16),
                    onTap: () => widget.onNavigationChanged(kIsWeb ? 15 : 16),
                    isCollapsed: true,
                    badgeCount: unreadChatCount,
                  ),
                  _SubNavItem(
                    label: 'All Chat',
                    icon: Icons.forum_rounded,
                    isSelected: widget.selectedIndex == 10,
                    onTap: () => widget.onNavigationChanged(10),
                    isCollapsed: true,
                    badgeCount: unreadChatCount,
                  ),
                  _SubNavItem(
                    label: 'Broadcast',
                    icon: Icons.radar_rounded,
                    isSelected: widget.selectedIndex == 9,
                    onTap: () => widget.onNavigationChanged(9),
                    isCollapsed: true,
                  ),
                ],

                const SizedBox(height: 12),
                // --- FLAT ITEMS (No Section Headers) ---
                _SubNavItem(
                  label: 'Notices',
                  icon: Icons.campaign_rounded,
                  isSelected: widget.selectedIndex == 7,
                  onTap: () => widget.onNavigationChanged(7),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Notes',
                  icon: Icons.sticky_note_2_rounded,
                  isSelected: widget.selectedIndex == 8,
                  onTap: () => widget.onNavigationChanged(8),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Asset Library',
                  icon: Icons.photo_library_rounded,
                  isSelected: widget.selectedIndex == 11,
                  onTap: () => widget.onNavigationChanged(11),
                  isCollapsed: widget.isCollapsed,
                ),
                const SizedBox(height: 12),
                if (!kIsWeb)
                  _SubNavItem(
                    label: 'Update',
                    icon: Icons.system_update_rounded,
                    isSelected: widget.selectedIndex == 13,
                    onTap: () => widget.onNavigationChanged(13),
                    isCollapsed: widget.isCollapsed,
                  ),
                _SubNavItem(
                  label: 'Guidelines',
                  icon: Icons.menu_book_rounded,
                  isSelected: widget.selectedIndex == (kIsWeb ? 13 : 14),
                  onTap: () => widget.onNavigationChanged(kIsWeb ? 13 : 14),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Modules',
                  icon: Icons.extension_rounded,
                  isSelected: widget.selectedIndex == (kIsWeb ? 14 : 15),
                  onTap: () => widget.onNavigationChanged(kIsWeb ? 14 : 15),
                  isCollapsed: widget.isCollapsed,
                ),
              ],
            ),
          ),
          _ProfileSection(isCollapsed: widget.isCollapsed, isDark: isDark),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCollapsed;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final bool isSpecial;
  final bool isSelected;
  final int badgeCount;

  const _NavGroup({
    required this.label,
    required this.icon,
    required this.isCollapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.isSpecial = false,
    this.isSelected = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return Column(children: children);

    final primaryColor = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : Colors.black87;

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: primaryColor.withOpacity(0.1), width: 0.5) : null,
            ),
            child: Row(
              children: [
                if (isSelected)
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 4)],
                    ),
                  ),
                Icon(
                  icon, 
                  size: 20, 
                  color: isSelected 
                      ? primaryColor 
                      : (isSpecial ? const Color(0xFF34D399) : (isDark ? Colors.white54 : Colors.black54)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: isSelected ? FontWeight.bold : (isExpanded ? FontWeight.bold : FontWeight.w500), 
                      color: isSelected ? (isDark ? Colors.white : primaryColor) : color,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isSelected ? primaryColor : (isDark ? Colors.white30 : Colors.black26),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(children: children),
          ),
      ],
    );
  }
}

class _SubNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNested;
  final bool isCollapsed;
  final bool isFirst;
  final bool isLast;
  final int badgeCount;

  const _SubNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isNested = false,
    this.isCollapsed = false,
    this.isFirst = false,
    this.isLast = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: AppColors.primary.withOpacity(0.25), width: 0.5)
                    : null,
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          // Hierarchy Lines (Mirrors EBM Central)
          if (!isCollapsed && isNested)
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 1.0,
                      height: 18,
                      margin: const EdgeInsets.only(left: 14),
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.0,
                          margin: const EdgeInsets.only(left: 14),
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        ),
                      ),
                  ],
                ),
                Container(
                  width: 14,
                  height: 1.0,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                ),
              ],
            ),
          
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                    if (badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool isCollapsed;
  final bool isDark;
  const _Logo({required this.isCollapsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
        ),
        if (!isCollapsed) ...[
          const SizedBox(width: 12),
          Text(
            'ebficbm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _AppBar extends StatelessWidget {
  final String title;
  final bool showMenu;
  const _AppBar({required this.title, this.showMenu = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          if (showMenu) ...[
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(IconsaxPlusLinear.menu_1),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _AppBarIcon(
                icon: Provider.of<ThemeProvider>(context).isDarkMode ? IconsaxPlusLinear.sun_1 : IconsaxPlusLinear.moon,
                onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _AppBarIcon(icon: IconsaxPlusLinear.notification, onTap: () => Scaffold.of(context).openEndDrawer(), isDark: isDark),
              const SizedBox(width: 12),
              Consumer<AuthProvider>(
                builder: (context, authState, _) {
                  return GestureDetector(
                    onTap: () => _showProfileDropdown(context, isDark, authState, isDark ? Colors.white : AppColors.textDark),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.person_outline, color: AppColors.primary, size: 16),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileDropdown(BuildContext context, bool isDark, AuthProvider authState, Color textColor) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutQuart.transform(anim1.value);
        return Transform.scale(
          scale: 0.95 + (0.05 * curve),
          child: Opacity(
            opacity: anim1.value,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
                  right: 16,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 320,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (authState.userName ?? "U")[0].toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                authState.userName ?? "User Identity",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                authState.userEmail ?? "identity@ebfic.store",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: textColor.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "Manage your EBM Identity",
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 1, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _showPreferencesDialog(context, isDark, textColor);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(IconsaxPlusLinear.setting_2, size: 20, color: textColor.withOpacity(0.8)),
                                  const SizedBox(width: 16),
                                  Text(
                                    "Preferences (Language & Currency)",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(height: 1, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              authState.logout();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent.withOpacity(0.8)),
                                  const SizedBox(width: 16),
                                  Text(
                                    "Sign out of all accounts",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(height: 1, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Privacy Policy", style: GoogleFonts.outfit(fontSize: 12, color: textColor.withOpacity(0.5))),
                              const SizedBox(width: 16),
                              Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: textColor.withOpacity(0.3))),
                              const SizedBox(width: 16),
                              Text("Terms of Service", style: GoogleFonts.outfit(fontSize: 12, color: textColor.withOpacity(0.5))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPreferencesDialog(BuildContext context, bool isDark, Color textColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<TdSetProvider>(
          builder: (context, tdSet, child) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Preferences", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Language", style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: tdSet.availableLanguages.map((lang) {
                      final selected = tdSet.language == lang;
                      return ChoiceChip(
                        label: Text(lang == 'en' ? 'English' : 'বাংলা'),
                        selected: selected,
                        onSelected: (val) {
                          if (val) tdSet.updateUserPreference(lang, tdSet.currency, context.read<AuthProvider>());
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(color: selected ? AppColors.primary : textColor),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text("Currency", style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: tdSet.exchangeRates.keys.map((curr) {
                      final selected = tdSet.currency == curr;
                      return ChoiceChip(
                        label: Text(curr),
                        selected: selected,
                        onSelected: (val) {
                          if (val) tdSet.updateUserPreference(tdSet.language, curr, context.read<AuthProvider>());
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(color: selected ? AppColors.primary : textColor),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Done", style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _AppBarIcon({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final bool isCollapsed;
  final bool isDark;
  const _ProfileSection({required this.isCollapsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16, vertical: 12),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.logout_rounded, 
            color: isDark ? Colors.white54 : Colors.black54, 
            size: 20
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 16),
            Text(
              'Logout', 
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87, 
                fontWeight: FontWeight.w500,
                fontSize: 14,
              )
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Tooltip(
        message: 'Logout',
        child: InkWell(
          onTap: () => context.read<AuthProvider>().logout(),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.redAccent.withOpacity(0.08),
          child: content,
        ),
      ),
    );
  }
}
