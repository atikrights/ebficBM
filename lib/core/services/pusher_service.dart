import '../config/app_config.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Returns true only when pusher_channels_flutter has a native plugin implementation.
/// Supported: Android, iOS, Web.
/// NOT supported: Windows, macOS, Linux → calling .init() throws MissingPluginException.
bool get _isPusherSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  // Nullable — never instantiated on unsupported platforms
  PusherChannelsFlutter? _pusher;

  PusherChannelsFlutter _getPusher() {
    _pusher ??= PusherChannelsFlutter.getInstance();
    return _pusher!;
  }

  final List<Function(PusherEvent)> _listeners = [];
  bool _isInitialized = false;

  Future<void> init({String? token}) async {
    // Skip entirely on Windows / macOS / Linux
    if (!_isPusherSupported) {
      log("Pusher: Not supported on this platform — skipping init.");
      return;
    }

    try {
      final p = _getPusher();

      // Disconnect first if already connected (to apply new auth headers)
      if (_isInitialized) {
        await p.disconnect();
        _isInitialized = false;
      }

      await p.init(
        apiKey: AppConfig.pusherKey,
        cluster: AppConfig.pusherCluster,
        useTLS: true,
        authEndpoint: AppConfig.authEndpoint,
        authParams: token != null
            ? {
                'headers': {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                }
              }
            : null,
        onConnectionStateChange: (currentState, previousState) {
          log("Pusher Connection State: $currentState");
        },
        onEvent: (event) {
          log("Pusher Event: ${event.eventName} data: ${event.data}");
          for (var listener in List.from(_listeners)) {
            listener(event);
          }
        },
        onError: (message, code, e) {
          log("Pusher Error: $message code: $code exception: $e");
        },
        onSubscriptionSucceeded: (channelName, data) {
          log("Pusher Subscribed to $channelName");
        },
      );

      // Only subscribe to global channel if we have a token (likely admin/manager)
      if (token != null) {
        final prefix = AppConfig.envPrefix;
        await p.subscribe(channelName: "private-${prefix}ebm-global");
      }

      await p.connect();
      _isInitialized = true;
      log("Pusher Connected Successfully (Token: ${token != null ? 'Yes' : 'No'})");
    } catch (e) {
      log("Pusher Initialization Error: $e");
    }
  }

  Future<void> subscribeToUserChannels(int userId) async {
    if (!_isPusherSupported || !_isInitialized) return;
    try {
      final prefix = AppConfig.envPrefix;
      final channelName = "private-${prefix}dm.$userId";
      await _getPusher().subscribe(channelName: channelName);
      log("Pusher Subscribing to user channel: $channelName");
    } catch (e) {
      log("Pusher User Subscription Error: $e");
    }
  }

  Future<void> unsubscribeFromUserChannels(int userId) async {
    if (!_isPusherSupported || !_isInitialized) return;
    try {
      final prefix = AppConfig.envPrefix;
      await _getPusher().unsubscribe(channelName: "private-${prefix}dm.$userId");
    } catch (e) {}
  }

  void addListener(Function(PusherEvent) callback) {
    _listeners.add(callback);
  }

  void removeListener(Function(PusherEvent) callback) {
    _listeners.remove(callback);
  }
}
