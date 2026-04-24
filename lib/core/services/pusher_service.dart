import 'dart:developer';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  Future<void> init() async {
    try {
      await pusher.init(
        apiKey: const String.fromEnvironment('PUSHER_KEY', defaultValue: "194c83322db5de281baf"),
        cluster: "ap2",
        onEvent: (event) {
          log("Pusher Event: ${event.eventName} data: ${event.data}");
        },
        onError: (message, code, e) {
          log("Pusher Error: $message code: $code exception: $e");
        },
        onSubscriptionSucceeded: (channelName, data) {
          log("Pusher Subscribed to $channelName");
        },
      );
      
      await pusher.subscribe(channelName: "ebm-global");
      await pusher.connect();
      log("Pusher Connected Successfully");
    } catch (e) {
      log("Pusher Initialization Error: $e");
    }
  }

  void onEvent(String eventName, Function(dynamic) callback) {
    // Custom logic to handle specific events can be added here
  }
}
