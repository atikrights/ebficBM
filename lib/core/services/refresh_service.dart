import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ebficBM/features/companies/providers/company_provider.dart';
import 'package:ebficBM/features/projects/providers/project_provider.dart';
import 'package:ebficBM/features/tasks/providers/task_provider.dart';

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
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      // Sync reloads trigger internal async storage load + notifyListeners
      context.read<ProjectProvider>().reload();
      context.read<TaskProvider>().reload();
      context.read<CompanyProvider>().reload();
      
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Data synchronized', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 8,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshService(
      refresh: _refresh,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refresh,
          const SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true): _refresh,
          const SingleActivator(LogicalKeyboardKey.f5): _refresh,
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_isRefreshing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 3,
                  ),
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
    final service = RefreshService.of(context);
    if (service == null) return child;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      onRefresh: service.refresh,
      child: child,
    );
  }
}
