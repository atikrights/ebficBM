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
                // --- OVERVIEW GROUP ---
                _NavGroup(
                  label: 'Overview',
                  icon: IconsaxPlusLinear.home,
                  isCollapsed: widget.isCollapsed,
                  isExpanded: _expandedGroups['Overview'] ?? false,
                  onToggle: () => _toggleGroup('Overview'),
                  children: [
                    _SubNavItem(
                      label: 'Dashboard',
                      icon: IconsaxPlusLinear.element_3,
                      isSelected: widget.selectedIndex == 0,
                      onTap: () => widget.onNavigationChanged(0),
                      isFirst: true,
                    ),
                    _SubNavItem(
                      label: 'Analysis',
                      icon: IconsaxPlusLinear.graph,
                      isSelected: widget.selectedIndex == 1,
                      onTap: () => widget.onNavigationChanged(1),
                      isLast: true,
                    ),
                  ],
                ),

                // --- WORKPLACE GROUP ---
                _NavGroup(
                  label: 'Workplace',
                  icon: IconsaxPlusLinear.briefcase,
                  isCollapsed: widget.isCollapsed,
                  isExpanded: _expandedGroups['Workplace'] ?? false,
                  onToggle: () => _toggleGroup('Workplace'),
                  children: [
                    _SubNavItem(
                      label: 'Companies',
                      icon: IconsaxPlusLinear.building,
                      isSelected: widget.selectedIndex == 2,
                      onTap: () => widget.onNavigationChanged(2),
                      isFirst: true,
                    ),
                    _SubNavItem(
                      label: 'Projects',
                      icon: IconsaxPlusLinear.category,
                      isSelected: widget.selectedIndex == 3,
                      onTap: () => widget.onNavigationChanged(3),
                    ),
                    _SubNavItem(
                      label: 'Tasks',
                      icon: IconsaxPlusLinear.task_square,
                      isSelected: widget.selectedIndex == 4,
                      onTap: () => widget.onNavigationChanged(4),
                    ),
                    _SubNavItem(
                      label: 'Finance',
                      icon: IconsaxPlusLinear.card,
                      isSelected: widget.selectedIndex == 5,
                      onTap: () => widget.onNavigationChanged(5),
                    ),
                    _SubNavItem(
                      label: 'Reports',
                      icon: IconsaxPlusLinear.document_text,
                      isSelected: widget.selectedIndex == 6,
                      onTap: () => widget.onNavigationChanged(6),
                      isLast: true,
                    ),
                  ],
                ),

                // --- CHAT GROUP ---
                _NavGroup(
                  label: 'Chat',
                  icon: IconsaxPlusLinear.messages_1,
                  isCollapsed: widget.isCollapsed,
                  isExpanded: _expandedGroups['Chat'] ?? false,
                  onToggle: () => _toggleGroup('Chat'),
                  isSpecial: true,
                  children: [
                    _SubNavItem(
                      label: 'All Chat',
                      icon: IconsaxPlusLinear.message_2,
                      isSelected: widget.selectedIndex == 10,
                      onTap: () => widget.onNavigationChanged(10),
                      isNested: true,
                      isFirst: true,
                    ),
                    _SubNavItem(
                      label: 'Broadcast',
                      icon: IconsaxPlusLinear.radar,
                      isSelected: widget.selectedIndex == 9,
                      onTap: () => widget.onNavigationChanged(9),
                      isNested: true,
                    ),
                    _SubNavItem(
                      label: 'Settings',
                      icon: IconsaxPlusLinear.setting_2,
                      isSelected: false,
                      onTap: () {},
                      isNested: true,
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // --- FLAT ITEMS (No Section Headers) ---
                _SubNavItem(
                  label: 'Notices',
                  icon: IconsaxPlusLinear.notification_status,
                  isSelected: widget.selectedIndex == 7,
                  onTap: () => widget.onNavigationChanged(7),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Notes',
                  icon: IconsaxPlusLinear.document_text,
                  isSelected: widget.selectedIndex == 8,
                  onTap: () => widget.onNavigationChanged(8),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Asset Library',
                  icon: IconsaxPlusLinear.folder_cloud,
                  isSelected: widget.selectedIndex == 11,
                  onTap: () => widget.onNavigationChanged(11),
                  isCollapsed: widget.isCollapsed,
                ),
                const SizedBox(height: 12),
                if (!kIsWeb)
                  _SubNavItem(
                    label: 'Update',
                    icon: IconsaxPlusLinear.refresh,
                    isSelected: widget.selectedIndex == 13,
                    onTap: () => widget.onNavigationChanged(13),
                    isCollapsed: widget.isCollapsed,
                  ),
                _SubNavItem(
                  label: 'Guidelines',
                  icon: IconsaxPlusLinear.book,
                  isSelected: widget.selectedIndex == (kIsWeb ? 13 : 14),
                  onTap: () => widget.onNavigationChanged(kIsWeb ? 13 : 14),
                  isCollapsed: widget.isCollapsed,
                ),
                _SubNavItem(
                  label: 'Modules',
                  icon: IconsaxPlusLinear.category,
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

  const _NavGroup({
    required this.label,
    required this.icon,
    required this.isCollapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return Column(children: children);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isSpecial ? const Color(0xFF34D399) : (isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500, color: color),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 6),
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

  const _SubNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isNested = false,
    this.isCollapsed = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCollapsed) {
      return IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: isSelected ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12)),
      );
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          // Hierarchy Lines (Mirrors EBM Central)
          if (!isCollapsed && (isNested || isFirst || isLast || true))
            Container(
              width: 32,
              child: Stack(
                children: [
                  // Vertical Line
                  if (!isFirst || !isLast)
                    Positioned(
                      left: 15, top: isFirst ? 20 : 0, bottom: isLast ? 24 : 0,
                      child: Container(width: 1.5, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                    ),
                  // Horizontal Line
                  Positioned(
                    left: 15, top: 24,
                    child: Container(width: 10, height: 1.5, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  ),
                ],
              ),
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
                      color: isSelected ? AppColors.primary : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.grey[400] : Colors.grey[700]),
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
          child: const Icon(IconsaxPlusBold.flag, color: Colors.white, size: 24),
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
    return InkWell(
      onTap: () => context.read<AuthProvider>().logout(),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(IconsaxPlusLinear.logout, color: Colors.grey, size: 20),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}
