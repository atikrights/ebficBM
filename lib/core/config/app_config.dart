import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Universal domain-aware configuration for EBM.
class AppConfig {
  AppConfig._internal();

  static const String _storageKey = 'ebm_base_url_override';
  static String? _customBaseUrl;

  /// Must be called once at app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString(_storageKey);
    } catch (_) {}
  }

  /// The Backend API URL (Smart Detection)
  static String get baseUrl {
    // 1. Check for manual override
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!.endsWith('/api') ? _customBaseUrl! : '$_customBaseUrl/api';
    }

    // 2. Check for build-time definition
    const definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl.endsWith('/api') ? definedUrl : '$definedUrl/api';
    }

    // 3. Web Smart Detection (Universal implementation)
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('ebfic.store')) {
        return 'https://api.ebfic.store/api';
      }
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:8000/api';
      }
      // If accessed via local network IP (e.g. 192.168.1.5)
      if (RegExp(r'^[0-9]+(?:\.[0-9]+){3}$').hasMatch(host)) {
        return 'http://$host:8000/api';
      }
      // For any other dynamic domain (e.g., custom server domain)
      // If the frontend is hosted on a domain, assume API is on api.<domain>
      final parts = host.split('.');
      if (parts.length > 2) {
        final rootDomain = parts.sublist(parts.length - 2).join('.');
        return 'https://api.$rootDomain/api';
      }
      return 'https://$host/api';
    }

    // 4. Final Fallback (Production vs Local Debug)
    if (kReleaseMode) return 'https://api.ebfic.store/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the special alias for your host loopback interface in Android Emulator
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// The EBM Central Portal URL for SSO.
  static String get centralUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('ebfic.store')) {
        return 'https://central.ebfic.store';
      }
      if (host == 'localhost' || host == '127.0.0.1') return 'http://127.0.0.1:3000';
      if (RegExp(r'^[0-9]+(?:\.[0-9]+){3}$').hasMatch(host)) return 'http://$host:3000';
      
      final parts = host.split('.');
      if (parts.length > 2) {
        final rootDomain = parts.sublist(parts.length - 2).join('.');
        return 'https://central.$rootDomain';
      }
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return kReleaseMode ? 'https://central.ebfic.store' : 'http://127.0.0.1:3000';
  }

  /// Whether the app is currently running on localhost (dev mode).
  static bool get isLocalhost {
    return baseUrl.contains('127.0.0.1') || baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2');
  }

  /// Origin for CORS and Auth (e.g., https://api.ebfic.store)
  static String get origin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}';
  }

  /// Broadcasting Auth Endpoint
  /// NOTE: Laravel's broadcasting/auth is NOT under /api prefix.
  static String get authEndpoint => '${baseUrl.replaceFirst('/api', '')}/broadcasting/auth';

  /// Pusher Configuration
  static const String pusherKey = "194c83322db5de281baf";
  static const String pusherCluster = "ap2";

  /// Asset Link Builders
  static String assetLink(String assetId) => '$baseUrl/assets/$assetId/view';
  static String sharedLink(String assetId) => '$baseUrl/assets/$assetId/share';

  /// Channel Prefix for Environment Isolation (Matches Backend & Central)
  static String get envPrefix => isLocalhost ? 'local.' : 'prod.';

  static final AppConfig instance = AppConfig._internal();
}
