import '../config/app_config.dart';
import 'dart:developer';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  final List<Function(PusherEvent)> _listeners = [];

  Future<void> init({String? token}) async {
    try {
      // If already connected, disconnect first to apply new auth headers
      await pusher.disconnect();
      
      await pusher.init(
        apiKey: AppConfig.pusherKey,
        cluster: AppConfig.pusherCluster,
        useTLS: true,
        authEndpoint: AppConfig.authEndpoint,
        authParams: token != null ? {
          'headers': {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }
        } : null,
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
        await pusher.subscribe(channelName: "private-ebm-global");
      }
      
      await pusher.connect();
      log("Pusher Connected Successfully (Token: ${token != null ? 'Yes' : 'No'})");
    } catch (e) {
      log("Pusher Initialization Error: $e");
    }
  }

  Future<void> subscribeToUserChannels(int userId) async {
    try {
      final channelName = "private-dm.$userId";
      await pusher.subscribe(channelName: channelName);
      log("Pusher Subscribing to user channel: $channelName");
    } catch (e) {
      log("Pusher User Subscription Error: $e");
    }
  }

  Future<void> unsubscribeFromUserChannels(int userId) async {
    try {
      await pusher.unsubscribe(channelName: "private-dm.$userId");
    } catch (e) {}
  }

  void addListener(Function(PusherEvent) callback) {
    _listeners.add(callback);
  }

  void removeListener(Function(PusherEvent) callback) {
    _listeners.remove(callback);
  }
}
