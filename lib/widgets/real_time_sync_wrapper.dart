import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/services/pusher_service.dart';
import 'package:ebficbm/core/services/refresh_service.dart';
import 'package:ebficbm/core/providers/auth_provider.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
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
    final triggerEvents = [
      'data.updated', 
      'data.refresh',
      'company.created', 
      'company.updated', 
      'company.deleted',
      'category.created', 
      'category.deleted'
    ];

    if (triggerEvents.contains(event.eventName)) {
      debugPrint('Real-time update received: ${event.eventName}');
      
      // Parse payload to check for team_switched event
      try {
        final dynamic rawData = event.data;
        final Map<String, dynamic> payload = rawData is String
            ? Map<String, dynamic>.from(json.decode(rawData))
            : Map<String, dynamic>.from(rawData as Map);

        if (payload['type'] == 'team_switched') {
          final int? switchedUserId = payload['user_id'] is int 
              ? payload['user_id'] 
              : int.tryParse(payload['user_id']?.toString() ?? '');

          if (mounted) {
            final authProvider = context.read<AuthProvider>();
            if (switchedUserId != null && authProvider.userId == switchedUserId) {
              // Context switched on another session - reload local cache
              context.read<TaskProvider>().reload();
              context.read<ProjectProvider>().reload();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Workspace context updated in real-time!"),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error decoding Pusher payload: $e');
      }
      
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
