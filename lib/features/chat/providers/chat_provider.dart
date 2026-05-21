import 'package:flutter/material.dart';
import '../data/chat_service.dart';
import '../../../core/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ChatService _service;
  final PusherService _pusher = PusherService();

  List<Map<String, dynamic>> _sessions = [];
  Map<String, List<Map<String, dynamic>>> _messages = {};
  final Map<String, bool> _typingStatus = {};
  bool _isLoading = false;
  String? _activeChatId;

  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoading => _isLoading;
  ChatService get service => _service;
  Map<String, bool> get typingStatus => _typingStatus;

  ChatProvider(this._service) {
    WidgetsBinding.instance.addObserver(this);
    _initPusherListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync gaps when app returns to foreground
      performDeltaSync();
      loadSessions();
    }
  }

  void _initPusherListener() {
    _pusher.addListener((event) {
      if (event.eventName == 'message.new') {
        _handleNewMessage(event.data);
      } else if (event.eventName == 'message.status') {
        _handleStatusUpdate(event.data);
      } else if (event.eventName == 'user.typing') {
        _handleTyping(event.data);
      } else if (event.eventName == 'data.updated' || event.eventName == 'message_update') {
        _handleMessageUpdate(event.data);
      } else if (event.eventName == 'pusher:connection_established') {
        loadSessions();
      }
    });
  }

  void setActiveChat(String receiverType) {
    _activeChatId = receiverType;
    if (int.tryParse(receiverType) != null) {
      _service.markAsRead(int.parse(receiverType));
    }
  }

  void clearActiveChat() {
    _activeChatId = null;
  }

  Future<void> _handleStatusUpdate(dynamic rawData) async {
    if (rawData == null) return;
    try {
      final Map<String, dynamic> data = rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);
      final String msgId = data['id']?.toString() ?? '';
      final String status = data['status'] ?? 'read';

      _messages.forEach((bucket, msgs) {
        for (var msg in msgs) {
          if (msg['id']?.toString() == msgId) {
            msg['status'] = status;
            if (status == 'delivered') msg['delivered_at'] = data['timestamp'];
            if (status == 'read') msg['read_at'] = data['timestamp'];
          }
        }
      });
      notifyListeners();
    } catch (e) {}
  }

  void _handleTyping(dynamic rawData) {
    if (rawData == null) return;
    final data = rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);
    final String senderId = data['sender_id'].toString();
    _typingStatus[senderId] = data['is_typing'] == true;
    notifyListeners();
  }

  Future<void> _handleNewMessage(dynamic rawData) async {
    if (rawData == null) return;
    try {
      final Map<String, dynamic> payload = rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);
      final String msgId = payload['id']?.toString() ?? '';
      final String clientId = payload['client_id']?.toString() ?? '';
      
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('user_id')?.toString();
      final senderIdStr = payload['sender_id']?.toString() ?? '';
      final receiverIdStr = payload['receiver_id']?.toString() ?? '';
      final receiverTypeStr = payload['receiver_type']?.toString() ?? '';
      final bool isMe = senderIdStr == currentUserId;
      
      String bucketKey = 'unknown';
      if (receiverTypeStr == 'ai' || receiverTypeStr == 'self') {
        bucketKey = receiverTypeStr;
      } else if (isMe) {
        bucketKey = receiverIdStr;
      } else {
        bucketKey = senderIdStr;
      }

      if (clientId.isNotEmpty) {
        final index = _messages[bucketKey]?.indexWhere((m) => m['id'] == clientId) ?? -1;
        if (index != -1) {
          _messages[bucketKey]![index] = { ...payload, 'isMe': true };
          notifyListeners();
          return;
        }
      }

      final bool alreadyExists = _messages[bucketKey]?.any((m) => m['id']?.toString() == msgId) ?? false;
      if (alreadyExists) return;

      final newMessage = <String, dynamic>{
        ...payload,
        'isMe': isMe,
        'message': payload['message'] ?? '',
        'status': payload['status'] ?? 'sent',
      };

      if (_messages.containsKey(bucketKey)) {
        _messages[bucketKey]!.add(newMessage);
      } else {
        _messages[bucketKey] = [newMessage];
      }
      
      _updateSessionLastMessage(bucketKey, payload['message'] ?? '', isMe: isMe, messageObj: newMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider Pusher Error: $e');
    }
  }

  void _handleMessageUpdate(dynamic rawData) {
    if (rawData == null) return;
    try {
      final Map<String, dynamic> data = rawData is String ? json.decode(rawData) : Map<String, dynamic>.from(rawData);
      final action = data['action'];
      final targetId = data['id'].toString();
      final receiverType = data['receiver_type']?.toString() ?? data['receiver_id']?.toString() ?? '';

      if (action == 'system_wipe') {
        _messages.clear();
        _sessions.clear();
        notifyListeners();
        return;
      }

      if (action == 'deleted' && _messages.containsKey(receiverType)) {
        _messages[receiverType]!.removeWhere((m) => m['id'].toString() == targetId);
      } else if (action == 'edited' && _messages.containsKey(receiverType)) {
        final newMsg = data['message'] ?? data['new_content'];
        for (var msg in _messages[receiverType]!) {
          if (msg['id'].toString() == targetId) msg['message'] = newMsg;
        }
        _updateSessionLastMessage(receiverType, newMsg, isMe: true);
      }
      notifyListeners();
    } catch (e) {}
  }

  void _updateSessionLastMessage(String receiverType, String message, {bool isMe = true, Map<String, dynamic>? messageObj}) {
    int sessionIndex = -1;
    for (int i = 0; i < _sessions.length; i++) {
      if (_sessions[i]['receiver_type']?.toString() == receiverType) {
        sessionIndex = i;
        break;
      }
    }
    
    if (sessionIndex != -1) {
      final session = _sessions.removeAt(sessionIndex);
      session['last_message'] = message;
      session['updated_at'] = DateTime.now().toIso8601String();
      if (messageObj != null) {
        session['last_msg_obj'] = {
          'status': messageObj['status'],
          'is_mine': isMe,
          'created_at': session['updated_at'],
        };
      }
      if (!isMe && _activeChatId != receiverType) {
        session['unread_count'] = (session['unread_count'] ?? 0) + 1;
      }
      _sessions.insert(0, session);
      notifyListeners();
    } else {
      // New conversation from someone else or from another device, fetch sessions again
      loadSessions();
    }
  }

  Future<void> performDeltaSync() async {
    int maxId = 0;
    _messages.values.forEach((list) {
      for (var m in list) {
        int id = int.tryParse(m['id'].toString()) ?? 0;
        if (id > maxId) maxId = id;
      }
    });
    if (maxId == 0) return;
    try {
      final List<dynamic> newMessages = await _service.getDeltaSync(maxId);
      for (var msg in newMessages) _handleNewMessage(msg);
    } catch (e) {}
  }

  Future<void> loadSessions() async {
    if (_isLoading) return; // Prevent duplicate concurrent loads
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _service.getChatSessions().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Load Sessions Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getMessages(String receiverType) {
    return _messages[receiverType] ?? [];
  }

  Future<void> loadMessages(String receiverType) async {
    _isLoading = true;
    notifyListeners();
    try {
      _messages[receiverType] = await _service.getChats(receiverType).timeout(const Duration(seconds: 10));
      if (int.tryParse(receiverType) != null) _service.markAsRead(int.parse(receiverType));
    } catch (e) {
      debugPrint("Load Messages ($receiverType) Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String receiverType, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = <String, dynamic>{
      'id': clientId,
      'client_id': clientId,
      'sender_id': currentUserId,
      'message': text,
      'isMe': true,
      'status': 'sending',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!_messages.containsKey(receiverType)) _messages[receiverType] = [];
    _messages[receiverType]!.add(optimisticMsg);
    _updateSessionLastMessage(receiverType, text, isMe: true);
    notifyListeners();

    try {
      await _service.sendMessageWithClientId(receiverType, text, clientId);
    } catch (e) {
      final index = _messages[receiverType]!.indexWhere((m) => m['id'] == clientId);
      if (index != -1) _messages[receiverType]![index]['status'] = 'failed';
      notifyListeners();
    }
  }

  Future<void> resendMessage(String receiverType, String tempId) async {
    final idx = _messages[receiverType]?.indexWhere((m) => m['id'] == tempId) ?? -1;
    if (idx == -1) return;
    final text = _messages[receiverType]![idx]['message'];
    _messages[receiverType]![idx]['status'] = 'sending';
    notifyListeners();
    try {
      await _service.sendMessageWithClientId(receiverType, text, tempId);
    } catch (e) {
      _messages[receiverType]![idx]['status'] = 'failed';
      notifyListeners();
    }
  }
}
