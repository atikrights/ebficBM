import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Universal domain-aware configuration for EBM.
class AppConfig {
  AppConfig._internal();
  static final AppConfig instance = AppConfig._internal();

  static const String _storageKey = 'ebm_base_url_override';
  String? _customBaseUrl;

  /// Must be called once at app startup
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString(_storageKey);
    } catch (_) {}
  }

  /// The Backend API URL (Smart Detection)
  String get baseUrl {
    // 1. Check for manual override (used in dev settings)
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!.endsWith('/api') ? _customBaseUrl! : '$_customBaseUrl/api';
    }

    // 2. Check for build-time definition (--dart-define=API_URL=...)
    const definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl.endsWith('/api') ? definedUrl : '$definedUrl/api';
    }

    // 3. Environment-based fallback
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') return 'http://127.0.0.1:8000/api';
      final domainParts = host.split('.');
      if (domainParts.length >= 2) {
        final rootDomain = domainParts.sublist(domainParts.length - 2).join('.');
        return 'https://api.$rootDomain/api';
      }
    }

    // 4. Final Fallback (Production vs Local Debug)
    if (kReleaseMode) return 'https://api.ebfic.store/api';
    return 'http://127.0.0.1:8000/api';
  }

  /// Origin for CORS and Auth (e.g., https://api.ebfic.store)
  String get origin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}';
  }

  /// Broadcasting Auth Endpoint
  String get authEndpoint => '$baseUrl/broadcasting/auth';

  /// Pusher Configuration
  static const String pusherKey = "194c83322db5de281baf";
  static const String pusherCluster = "ap2";

  /// Asset Link Builders
  String assetLink(String assetId) => '$baseUrl/assets/$assetId/view';
  String sharedLink(String assetId) => '$baseUrl/assets/$assetId/share';
}
