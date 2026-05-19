import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
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
  bool get isSubAdmin => _userRole?.toUpperCase() == 'SUB_ADMIN';
  bool get isManager => _userRole?.toUpperCase() == 'MANAGER';
  bool get isAuthority => isAdmin || isSuperAdmin;
  bool get canCreateItems => isSuperAdmin || isAdmin || isSubAdmin || isManager;

  int? get userId => _userId;
  String? get chatProfileId => _chatProfileId;
  String? get chatNumber => _chatNumber;
  String? get chatNickname => _chatNickname;
  String? get chatBio => _chatBio;
  String? get chatAbout => _chatAbout;

  ApiService get api => _api;

  AuthProvider() {
    _restoreSession();
    
    // ── Real-Time Policy & Role Eviction Listener ─────────────────────
    PusherService().addListener((event) {
      if (event.eventName == 'data.updated') {
        try {
          final dynamic rawData = event.data;
          final Map<String, dynamic> data = rawData is String
              ? Map<String, dynamic>.from(json.decode(rawData))
              : Map<String, dynamic>.from(rawData as Map);

          if (data['type'] == 'security_eviction') {
            final bool canLogin = data['can_login'] ?? true;
            if (!canLogin) {
              logout();
            } else {
              _restoreSession();
            }
          }
        } catch (e) {
          debugPrint("Error handling pusher security eviction: $e");
        }
      }
    });
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('ebm_secure_device_id') ?? '';
    
    // Attempt to read encrypted token. If not present, fall back to plain token (migration)
    String? token = await SecureLocalStore.readDecrypted('auth_token', deviceId);
    if (token == null) {
      token = prefs.getString('auth_token');
      if (token != null && deviceId.isNotEmpty) {
        await SecureLocalStore.saveEncrypted('auth_token', token, deviceId);
        await prefs.remove('auth_token'); // clean up legacy unencrypted key
      }
    }
    
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

  Future<Map<String, dynamic>> _getDeviceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('ebm_secure_device_id');
    if (deviceId == null) {
      final random = math.Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      values[6] = (values[6] & 0x0f) | 0x40;
      values[8] = (values[8] & 0x3f) | 0x80;
      
      final buffer = StringBuffer();
      for (int i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
          buffer.write('-');
        }
        buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
      }
      deviceId = buffer.toString();
      await prefs.setString('ebm_secure_device_id', deviceId);
    }

    String osType = 'unknown';
    String deviceName = 'Unknown Client';
    
    if (kIsWeb) {
      osType = 'web';
      deviceName = 'Web Browser';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          osType = 'android';
          deviceName = 'Android Device';
          break;
        case TargetPlatform.iOS:
          osType = 'ios';
          deviceName = 'iOS Device';
          break;
        case TargetPlatform.windows:
          osType = 'windows';
          deviceName = 'Windows App';
          break;
        case TargetPlatform.macOS:
          osType = 'macos';
          deviceName = 'Mac App';
          break;
        case TargetPlatform.linux:
          osType = 'linux';
          deviceName = 'Linux App';
          break;
        default:
          break;
      }
    }

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'os_type': osType,
      'fingerprint_data': {
        'platform': osType,
        'app_version': '1.1.62',
        'is_web': kIsWeb,
      },
    };
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceDetails = await _getDeviceDetails();
      final response = await _api.post('/login', {
        'email': email,
        'password': password,
        ...deviceDetails,
      });

      final String token = response['access_token'];
      final userData = response['user'];
      final String role = userData['role'];
      final String name = userData['name'];
      final String uEmail = userData['email'];

      final prefs = await SharedPreferences.getInstance();
      final String deviceId = deviceDetails['device_id'];

      // Save token securely with Device-Bound Encryption
      await SecureLocalStore.saveEncrypted('auth_token', token, deviceId);
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
      final deviceDetails = await _getDeviceDetails();
      final String deviceId = deviceDetails['device_id'];

      await SecureLocalStore.saveEncrypted('auth_token', token, deviceId);
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
      final deviceDetails = await _getDeviceDetails();
      final String deviceId = deviceDetails['device_id'];

      await SecureLocalStore.saveEncrypted('auth_token', authToken, deviceId);
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
    await SecureLocalStore.clear('auth_token');
    
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

// ─── Secure Local Store (Device-Bound Encryption Wrapper) ───────────────────────
class SecureLocalStore {
  static enc.Key _deriveKey(String deviceId) {
    const rawSalt = 'ebm_secure_salt_789_dbe_key';
    final combined = '$deviceId|$rawSalt';
    // Use SHA-256 to ensure the key is always perfectly 32 bytes and heavily scrambled
    final hash = crypto.sha256.convert(utf8.encode(combined));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  static final _iv = enc.IV.fromLength(16);

  static Future<void> saveEncrypted(String key, String value, String deviceId) async {
    if (deviceId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final aesKey = _deriveKey(deviceId);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(value, iv: _iv);
    await prefs.setString('enc_$key', encrypted.base64);
  }

  static Future<String?> readDecrypted(String key, String deviceId) async {
    if (deviceId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final base64Value = prefs.getString('enc_$key');
    if (base64Value == null) return null;

    try {
      final aesKey = _deriveKey(deviceId);
      final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(base64Value, iv: _iv);
      // Validation: If the decrypted token contains non-printable control characters 
      // or non-ASCII garbage characters (due to encryption/decryption key misalignment),
      // it means the key/token changed or it's corrupted.
      final cleanDecrypted = decrypted.trim();
      final hasNonAsciiOrControl = cleanDecrypted.codeUnits.any((char) => char < 32 || char > 126);
      if (hasNonAsciiOrControl) {
        await clear(key); // wipe the corrupted token
        return null;
      }
      
      return cleanDecrypted;
    } catch (_) {
      await clear(key);
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_$key');
  }
}
