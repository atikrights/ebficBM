import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import '../services/pusher_service.dart' as import_pusher;

class TeamProvider extends ChangeNotifier {
  ApiService? _api;
  
  Map<String, dynamic>? _currentTeam;
  List<dynamic> _teams = [];
  bool _isLoading = false;
  bool _pusherInitialized = false;

  Map<String, dynamic>? get currentTeam => _currentTeam;
  List<dynamic> get teams => _teams;
  bool get isLoading => _isLoading;

  void update(ApiService api) {
    _api = api;
    fetchTeams();
    _initPusher();
  }

  void _initPusher() {
    if (_pusherInitialized) return;
    try {
      import_pusher.PusherService().addListener((event) {
        if (event.eventName == 'data.updated' || event.eventName == r'App\Events\DataUpdated') {
          try {
            final Map<String, dynamic> payload = json.decode(event.data.toString());
            final data = payload['data'] ?? payload;
            if (data is Map && data['type'] == 'team') {
              fetchTeams(); // Re-sync team state
            }
          } catch (_) {
            // Ignore parse errors
          }
        }
      });
      _pusherInitialized = true;
    } catch (e) {
      debugPrint('TeamProvider Pusher Init Error: $e');
    }
  }

  Future<void> fetchTeams() async {
    if (_api == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api!.get('/teams');
      if (response != null && response['teams'] != null) {
        _teams = response['teams'];
        // Find current active team
        final currentId = response['current_team_id'];
        if (currentId != null && _teams.isNotEmpty) {
          _currentTeam = _teams.firstWhere(
            (t) => t['id'] == currentId,
            orElse: () => _teams.first,
          );
        } else if (_teams.isNotEmpty) {
          _currentTeam = _teams.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> inviteAdmin(String email) async {
    if (_api == null) return null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api!.post('/teams/invite-admin', {'email': email});
      return response['token']; // The token returned by the server
    } catch (e) {
      debugPrint('Error inviting admin: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptInvitation(String token) async {
    if (_api == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _api!.post('/teams/accept-invite', {'token': token});
      await fetchTeams(); // Refresh data after merging
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
