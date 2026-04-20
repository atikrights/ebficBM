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

  /// The root origin (no trailing slash).
  /// Web   → auto from browser: http://localhost:5555, https://ebficbm.com, etc.
  /// Other → custom override or production fallback.
  String get origin {
    if (kIsWeb) {
      // Uri.base is always the current browser URL — works on ANY domain.
      return Uri.base.origin;
    }
    return _customBaseUrl ?? 'https://ebficbm.com';
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
