import 'package:flutter/foundation.dart';
import '../../../core/network/api_service.dart';

class ChatService {
  final ApiService _api;

  ChatService(this._api);

  /// Fetch all active chat sessions (Communities/DMs)
  Future<List<Map<String, dynamic>>> getChatSessions() async {
    try {
      final response = await _api.get('/dm/conversations');
      if (response is List) {
        return response.map((s) {
          final data = Map<String, dynamic>.from(s);
          final user = data['user'] ?? {};
          final lastMsg = data['last_message'] ?? {};
          return {
            'chat_name': user['name'] ?? 'Unknown',
            'receiver_type': user['id']?.toString() ?? '',
            'last_message': lastMsg['message'] ?? 'No messages yet',
            'last_msg_obj': lastMsg,
            'unread_count': data['unread_count'] ?? 0,
            'updated_at': lastMsg['created_at'] ?? data['updated_at'],
            'chat_color': '#4F46E5', // AppColors.primary
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ChatService Error (getChatSessions): $e');
      return [];
    }
  }

  /// Get chat history for a specific receiver
  Future<List<Map<String, dynamic>>> getChats(String receiverType) async {
    try {
      if (int.tryParse(receiverType) != null) {
        // P2P Chat
        final response = await _api.get('/dm/messages/$receiverType');
        final data = (response is Map && response.containsKey('data')) ? response['data'] : response;
        if (data is List) {
          final otherId = int.parse(receiverType);
          return data.map((d) {
            final mapData = Map<String, dynamic>.from(d);
            final message = mapData['message'] ?? '';
            final senderId = mapData['sender_id'];
            return <String, dynamic>{
              ...mapData,
              'isMe': senderId != otherId,
              'message': message,
            };
          }).toList();
        }
      } else {
        // AI / Self Chat
        final response = await _api.get('/chats?receiver_type=$receiverType');
        if (response is List) {
          return response.map((data) {
            final mapData = Map<String, dynamic>.from(data);
            final message = mapData['message'] ?? '';
            final isAi = mapData['is_ai'] == true;
            return <String, dynamic>{
              ...mapData,
              'isMe': !isAi, // if it's not AI, it's me
              'message': message,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('ChatService Error (getChats): $e');
      return [];
    }
  }

  /// Send and Sync a message
  Future<Map<String, dynamic>?> syncMessage(String receiverType, String message) async {
    try {
      dynamic response;
      if (int.tryParse(receiverType) != null) {
        response = await _api.post('/dm/send', {
          'receiver_id': receiverType,
          'message_type': 'text',
          'message': message,
        });
      } else {
        response = await _api.post('/chats', {
          'receiver_type': receiverType,
          'message': message,
        });
      }
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('ChatService Error (syncMessage): $e');
      rethrow;
    }
  }

  /// AI Assistant logic (Generate response)
  Future<String> getAiReply(String prompt) async {
    try {
      final response = await _api.post('/chat/ai/generate', {'prompt': prompt});
      return response['reply'] ?? '';
    } catch (e) {
      debugPrint('ChatService Error (getAiReply): $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(int senderId) async {
    try {
      await _api.patch('/dm/read/$senderId');
    } catch (e) {
      debugPrint('ChatService Error (markAsRead): $e');
    }
  }

  /// Setup Profile (Initialize ID and Nickname)
  Future<Map<String, dynamic>> setupProfileWithResponse(String nickname) async {
    try {
      final response = await _api.post('/chat/profile/setup', {
        'chat_nickname': nickname,
      });
      return response;
    } catch (e) {
      debugPrint('ChatService Error (setupProfile): $e');
      rethrow;
    }
  }

  /// Update Profile (Bio, About, Nickname)
  Future<void> updateProfile({String? nickname, String? bio, String? about}) async {
    try {
      await _api.post('/chat/profile/update', {
        'chat_nickname': nickname,
        'chat_bio': bio,
        'chat_about': about,
      });
    } catch (e) {
      debugPrint('ChatService Error (updateProfile): $e');
      rethrow;
    }
  }

  /// Get team members for new chat list
  Future<List<Map<String, dynamic>>> getTeamUsers() async {
    try {
      final response = await _api.get('/chat/profile/team');
      if (response is List) {
        return response.map((u) => Map<String, dynamic>.from(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ChatService Error (getTeamUsers): $e');
      return [];
    }
  }

  /// Fetch only new messages since the last known ID (Gap Filling)
  Future<List<dynamic>> getDeltaSync(int lastId) async {
    try {
      final response = await _api.get('/dm/sync?last_id=$lastId');
      return response is List ? response : [];
    } catch (e) {
      debugPrint('Delta Sync Error: $e');
      return [];
    }
  }

  /// Send message with client_id for Optimistic UI reconciliation
  Future<Map<String, dynamic>?> sendMessageWithClientId(String receiverType, String text, String clientId) async {
    try {
      dynamic response;
      if (int.tryParse(receiverType) != null) {
        response = await _api.post('/dm/send', {
          'receiver_id': receiverType,
          'message': text,
          'client_id': clientId,
        });
      } else {
        response = await _api.post('/chats', {
          'receiver_type': receiverType,
          'message': text,
          'client_id': clientId,
        });
      }
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('Send Message Error: $e');
      rethrow;
    }
  }

  /// Find a user by their 12-digit virtual number
  Future<Map<String, dynamic>?> findUserByNumber(String number) async {
    try {
      final response = await _api.get('/chat/profile/find/$number');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('ChatService Error (findUserByNumber): $e');
      return null;
    }
  }
}
