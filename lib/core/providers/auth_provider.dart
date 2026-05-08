import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';
import '../services/pusher_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  int? _userId;
  String? _chatProfileId;
  String? _chatNumber;
  String? _chatNickname;
  String? _chatBio;
  String? _chatAbout;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isSuperAdmin => _userRole?.toUpperCase() == 'SUPER_ADMIN';
  bool get isAdmin => _userRole?.toUpperCase() == 'ADMIN' || isSuperAdmin;
  bool get isManager => _userRole?.toUpperCase() == 'MANAGER';
  bool get isAuthority => isAdmin || isSuperAdmin;

  int? get userId => _userId;
  String? get chatProfileId => _chatProfileId;
  String? get chatNumber => _chatNumber;
  String? get chatNickname => _chatNickname;
  String? get chatBio => _chatBio;
  String? get chatAbout => _chatAbout;

  ApiService get api => _api;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');

    if (token != null && role != null) {
      _api.setToken(token);
      try {
        // Verify token with backend
        final response = await _api.get('/user');
        _isLoggedIn = true;
        _userRole = role;
        _userName = name ?? response['name'];
        _userEmail = email ?? response['email'];
        _userId = response['id'];
        _chatProfileId = response['chat_profile_id'];
        _chatNumber = response['chat_number'];
        _chatNickname = response['chat_nickname'];
        _chatBio = response['chat_bio'];
        _chatAbout = response['chat_about'];
        
        // Subscribe to private channels
        await PusherService().init(token: token);
        PusherService().subscribeToUserChannels(_userId!);
        
        notifyListeners();
      } catch (e) {
        // If token is invalid (401), clear everything
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/login', {
        'email': email,
        'password': password,
      });

      final String token = response['access_token'];
      final userData = response['user'];
      final String role = userData['role'];
      final String name = userData['name'];
      final String uEmail = userData['email'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_role', role.toUpperCase());
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', uEmail);

      _api.setToken(token);
      _isLoggedIn = true;
      _userRole = role.toUpperCase();
      _userName = name;
      _userEmail = uEmail;
      _userId = userData['id'];
      _chatProfileId = userData['chat_profile_id'];
      _chatNumber = userData['chat_number'];
      _chatNickname = userData['chat_nickname'];
      _chatBio = userData['chat_bio'];
      _chatAbout = userData['chat_about'];
      _isLoading = false;
      
      // Subscribe to private channels
      await PusherService().init(token: token);
      PusherService().subscribeToUserChannels(_userId!);
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginWithToken(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _api.setToken(token);
      final userData = await _api.get('/user');
      final String role = userData['role'];
      final String name = userData['name'];
      final String uEmail = userData['email'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_role', role.toUpperCase());
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', uEmail);

      _isLoggedIn = true;
      _userRole = role.toUpperCase();
      _userName = name;
      _userEmail = uEmail;
      _userId = userData['id'];
      _isLoading = false;
      
      if (_userId != null) {
        await PusherService().init(token: token);
        PusherService().subscribeToUserChannels(_userId!);
      }
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _api.clearToken();
      notifyListeners();
    }
  }

  Future<void> join(String token, String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/register', {
        'invitation_token': token,
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final String authToken = response['access_token'];
      final userData = response['user'];
      final String role = userData['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', authToken);
      await prefs.setString('user_role', role.toUpperCase());
      await prefs.setString('user_name', name);

      _api.setToken(authToken);
      _isLoggedIn = true;
      _userRole = role.toUpperCase();
      _userName = name;
      _userId = userData['id'];
      _isLoading = false;
      
      if (_userId != null) {
        PusherService().subscribeToUserChannels(_userId!);
      }
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _api.clearToken();
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _userId = null;
    _chatProfileId = null;
    _chatNumber = null;
    _chatNickname = null;
    _chatBio = null;
    _chatAbout = null;
    
    // Unsubscribe from private channels
    if (_userId != null) {
      PusherService().unsubscribeFromUserChannels(_userId!);
    }
    
    notifyListeners();
  }

  void updateChatInfo({String? id, String? number, String? nickname, String? bio, String? about}) {
    if (id != null) _chatProfileId = id;
    if (number != null) _chatNumber = number;
    if (nickname != null) _chatNickname = nickname;
    if (bio != null) _chatBio = bio;
    if (about != null) _chatAbout = about;
    notifyListeners();
  }
}
