import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Universal domain-aware configuration for EBM.
/// Automatically detects environment:
///   - Web: reads live browser origin (localhost, ebficbm.com, any subdomain)
///   - Desktop/Mobile: uses stored base URL or falls back to production
class AppConfig {
  AppConfig._internal();
  static final AppConfig instance = AppConfig._internal();

  static const String _storageKey = 'ebm_base_url_override';

  String? _customBaseUrl;

  /// Must be called once at app startup (in main.dart or before first use).
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString(_storageKey);
    } catch (_) {}
  }

  /// Persist a custom base URL for desktop/mobile environments.
  Future<void> setBaseUrl(String url) async {
    _customBaseUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _customBaseUrl!);
    } catch (_) {}
  }

  Future<void> clearBaseUrl() async {
    _customBaseUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// The root origin of the frontend.
  String get origin => kIsWeb ? Uri.base.origin : (_customBaseUrl ?? (kDebugMode ? 'http://127.0.0.1:3000' : 'https://ebm-app.yourdomain.com'));

  /// The Backend API URL.
  /// Automatically maps subdomains to the central API on Hostinger.
  String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:8000/api';
      }
      
      // If running on e.g., central.ebfic.store or app.ebfic.store
      // we point to api.ebfic.store
      final domainParts = host.split('.');
      if (domainParts.length >= 2) {
        final rootDomain = domainParts.sublist(domainParts.length - 2).join('.');
        return 'https://api.$rootDomain/api';
      }
    }
    return '${_customBaseUrl ?? (kDebugMode ? 'http://127.0.0.1:8000' : 'https://api.ebfic.store')}/api';
  }

  /// The EBM Central Portal URL for SSO.
  /// Automatically maps [anything].[domain].com -> central.[domain].com
  String get centralUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:3000'; // Central dev port
      }
      
      final domainParts = host.split('.');
      if (domainParts.length >= 2) {
        final rootDomain = domainParts.sublist(domainParts.length - 2).join('.');
        return 'https://central.$rootDomain';
      }
    }
    return kDebugMode ? 'http://127.0.0.1:3000' : 'https://central.ebfic.store';
  }

  /// Whether the app is currently running on localhost (dev mode).
  bool get isLocalhost {
    if (kIsWeb) {
      final host = Uri.base.host;
      return host == 'localhost' || host == '127.0.0.1';
    }
    return _customBaseUrl?.contains('localhost') == true ||
        _customBaseUrl?.contains('127.0.0.1') == true;
  }

  // ------ Link Builders ------

  /// Public shareable asset link.
  String assetLink(String assetId) => '$origin/assets/$assetId';

  /// Public shared asset link (for external use).
  String sharedLink(String assetId) => '$origin/shared/$assetId';

  /// Company portal public link.
  String companyPortal(String companyId) => '$origin/portal/$companyId';

  /// Company logo CDN link (for hosted logos).
  String companyLogoLink(String companyId) => '$origin/logos/$companyId';

  /// Smart asset URL: returns hosted URL if available, else local path.
  String resolveAssetUrl({
    required String assetId,
    String? localPath,
    String? remoteUrl,
  }) {
    if (remoteUrl != null && remoteUrl.startsWith('http')) return remoteUrl;
    return assetLink(assetId);
  }
}
