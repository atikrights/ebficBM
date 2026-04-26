import 'package:flutter/material.dart';
import 'package:ebficbm/core/services/pusher_service.dart';
import 'package:ebficbm/core/services/refresh_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class RealTimeSyncWrapper extends StatefulWidget {
  final Widget child;
  const RealTimeSyncWrapper({super.key, required this.child});

  @override
  State<RealTimeSyncWrapper> createState() => _RealTimeSyncWrapperState();
}

class _RealTimeSyncWrapperState extends State<RealTimeSyncWrapper> {
  @override
  void initState() {
    super.initState();
    // Register listener for global data updates
    PusherService().addListener(_handlePusherEvent);
  }

  void _handlePusherEvent(PusherEvent event) {
    if (event.eventName == 'data.updated' || event.eventName == 'data.refresh') {
      debugPrint('Real-time update received: ${event.eventName}');
      
      // Trigger global refresh using the RefreshService
      if (mounted) {
        final refreshService = RefreshService.of(context);
        if (refreshService != null) {
          refreshService.refresh();
        }
      }
    }
  }

  @override
  void dispose() {
    PusherService().removeListener(_handlePusherEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
