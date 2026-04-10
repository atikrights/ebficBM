import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficBM/features/companies/providers/company_provider.dart';
import 'package:ebficBM/features/projects/providers/project_provider.dart';
import 'package:ebficBM/features/tasks/providers/task_provider.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// GlobalRefreshWrapper — wraps the entire app with:
/// • Ctrl+R / F5 keyboard shortcuts
/// • Exposes [RefreshService.of(context).refresh()]
class RefreshService extends InheritedWidget {
  final Future<void> Function() refresh;

  const RefreshService({
    super.key,
    required this.refresh,
    required super.child,
  });

  static RefreshService? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RefreshService>();
  }

  @override
  bool updateShouldNotify(RefreshService oldWidget) => false;
}

class GlobalRefreshWrapper extends StatefulWidget {
  final Widget child;
  const GlobalRefreshWrapper({super.key, required this.child});

  @override
  State<GlobalRefreshWrapper> createState() => _GlobalRefreshWrapperState();
}

class _GlobalRefreshWrapperState extends State<GlobalRefreshWrapper> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    if (_isRefreshing) {
      debugPrint('Sync in progress... ignoring duplicate command.');
      return;
    }
    
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact(); // Feel the refresh on mobile
    
    try {
      // 1. Core Data Sync
      context.read<ProjectProvider>().reload();
      context.read<TaskProvider>().reload();
      context.read<CompanyProvider>().reload();
      
      // 2. Wait for a smooth animation feel
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconsaxPlusBold.refresh, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text('System Synchronized', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: const Color(0xFF6366F1), // Indigo accent
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshService(
      refresh: _refresh,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refresh, // Windows / Linux
          const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _refresh,    // macOS Command + R
          const SingleActivator(LogicalKeyboardKey.f5): _refresh,                  // F5 for Web/Desktop
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_isRefreshing)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1), 
                          const Color(0xFF8B5CF6).withOpacity(0.5)
                        ],
                      ),
                    ),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ).animate().fadeIn(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  const AppRefreshIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = RefreshService.of(context);
    if (service == null) return child;

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF6366F1), // Indigo Primary
      strokeWidth: 2.5,
      displacement: 80,
      edgeOffset: 0,
      onRefresh: service.refresh,
      child: child,
    );
  }
}
