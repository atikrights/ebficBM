import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/providers/theme_provider.dart';
import 'package:ebficbm/features/notifications/screens/notifications_panel.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb

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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
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
      bottomNavigationBar: (isMobile)
          ? BottomNavigationBar(
              currentIndex: _mobileNavIndex(selectedIndex),
              onTap: (i) => onNavigationChanged(_mobileNavToScreenIndex(navIndex: i)),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: [
                const BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.element_3), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.task_square), label: 'Tasks'),
                const BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.card), label: 'Finance'),
                const BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.notification), label: 'Notices'),
                if (!kIsWeb)
                  const BottomNavigationBarItem(icon: Icon(IconsaxPlusLinear.refresh), label: 'Update'),
              ],
            )
          : null,
    );
  }
}

// Map screen index → mobile bottom nav index
int _mobileNavIndex(int screenIndex) {
  if (screenIndex == 0) return 0; // Dashboard
  if (screenIndex == 4) return 1; // Tasks
  if (screenIndex == 5) return 2; // Finance
  if (screenIndex == 7) return 3; // Notices
  if (!kIsWeb && screenIndex == 10) return 4; // Update
  return 0;
}

// Map mobile nav tap → actual screen index
int _mobileNavToScreenIndex({required int navIndex}) {
  if (navIndex == 0) return 0; // Dashboard
  if (navIndex == 1) return 4; // Tasks
  if (navIndex == 2) return 5; // Finance
  if (navIndex == 3) return 7; // Notices
  if (!kIsWeb && navIndex == 4) return 10; // Update
  return 0;
}



class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;
  final bool isCollapsed;

  const _Sidebar({
    required this.selectedIndex,
    required this.onNavigationChanged,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _Logo(isCollapsed: isCollapsed, isDark: isDark),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NavItem(
                  icon: IconsaxPlusLinear.element_3,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(0),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.graph,
                  label: 'Analysis',
                  isSelected: selectedIndex == 1,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(1),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.building,
                  label: 'Companies',
                  isSelected: selectedIndex == 2,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(2),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.category,
                  label: 'Projects',
                  isSelected: selectedIndex == 3,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(3),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.task_square,
                  label: 'Tasks',
                  isSelected: selectedIndex == 4,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(4),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.card,
                  label: 'Finance',
                  isSelected: selectedIndex == 5,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(5),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.graph,
                  label: 'Reports',
                  isSelected: selectedIndex == 6,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(6),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.notification_status, // Icon for Notices
                  label: 'Notices',
                  isSelected: selectedIndex == 7,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(7),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.document_text,
                  label: 'Notes',
                  isSelected: selectedIndex == 8,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(8),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.radar,
                  label: 'Broadcast',
                  isSelected: selectedIndex == 9,
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(9),
                  isDark: isDark,
                ),
                if (!kIsWeb)
                  _NavItem(
                    icon: IconsaxPlusLinear.refresh,
                    label: 'Update',
                    isSelected: selectedIndex == 10,
                    isCollapsed: isCollapsed,
                    onTap: () => onNavigationChanged(10),
                    isDark: isDark,
                  ),
                _NavItem(
                  icon: IconsaxPlusLinear.book,
                  label: 'Guidelines',
                  isSelected: selectedIndex == (kIsWeb ? 10 : 11),
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(kIsWeb ? 10 : 11),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: IconsaxPlusLinear.category,
                  label: 'Modules',
                  isSelected: selectedIndex == (kIsWeb ? 11 : 12),
                  isCollapsed: isCollapsed,
                  onTap: () => onNavigationChanged(kIsWeb ? 11 : 12),
                  isDark: isDark,
                ),

              ],
            ),
          ),
          _ProfileSection(isCollapsed: isCollapsed, isDark: isDark),
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
            color: Colors.black, // High-end black theme
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? (isDark ? Colors.white : AppColors.primary) 
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ]
          ],
        ),
      ),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 400;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(isNarrow ? 12 : 24, 16, 12, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showMenu) ...[
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(IconsaxPlusLinear.menu_1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isNarrow ? 18 : 22, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AppBarIcon(
                  icon: Provider.of<ThemeProvider>(context).isDarkMode ? IconsaxPlusLinear.sun_1 : IconsaxPlusLinear.moon,
                  onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                  isDark: isDark,
                  size: isNarrow ? 18 : 20,
                ),
                if (!isNarrow) const SizedBox(width: 4),
                _AppBarIcon(
                  icon: IconsaxPlusLinear.search_normal, 
                  onTap: () {}, 
                  isDark: isDark,
                  size: isNarrow ? 18 : 20,
                ),
                if (!isNarrow) const SizedBox(width: 4),
                _AppBarIcon(
                  icon: IconsaxPlusLinear.notification, 
                  onTap: () => Scaffold.of(context).openEndDrawer(), 
                  isDark: isDark,
                  size: isNarrow ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: isNarrow ? 14 : 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(IconsaxPlusLinear.user, color: Colors.white, size: isNarrow ? 14 : 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final double size;
  const _AppBarIcon({required this.icon, required this.onTap, required this.isDark, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: size),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final bool isCollapsed;
  final bool isDark;
  const _ProfileSection({required this.isCollapsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (isCollapsed)
            Icon(IconsaxPlusLinear.logout, color: isDark ? Colors.grey : Colors.grey[600])
          else ...[
            Icon(IconsaxPlusLinear.logout, color: isDark ? Colors.grey : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey[700], 
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
