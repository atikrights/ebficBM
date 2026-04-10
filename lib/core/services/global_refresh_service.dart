import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A high-performance, singleton service to manage global app refreshes.
/// Prevents duplicate triggers and ensures smooth synchronization across all devices.
class GlobalRefreshService {
  static final GlobalRefreshService _instance = GlobalRefreshService._internal();
  factory GlobalRefreshService() => _instance;
  GlobalRefreshService._internal();

  final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
  bool _isRefreshing = false;

  /// Triggers a global refresh event across the entire application.
  /// Safely ignores repeated calls to prevent slowdowns or conflicts.
  Future<void> triggerRefresh() async {
    if (_isRefreshing) {
      debugPrint('Refresh already in progress. Ignoring duplicate request.');
      return;
    }

    _isRefreshing = true;
    debugPrint('Global Refresh Triggered!');
    
    // Increment the notifier to signal all listening screens to refresh
    refreshNotifier.value++;
    
    // Add a small cool-down to prevent rapid-fire spamming
    await Future.delayed(const Duration(milliseconds: 800));
    _isRefreshing = false;
  }
}

/// Logical Key Set for Ctrl + R shortcut
class RefreshIntent extends Intent {
  const RefreshIntent();
}

class RefreshAction extends Action<RefreshIntent> {
  @override
  void invoke(RefreshIntent intent) {
    GlobalRefreshService().triggerRefresh();
  }
}
