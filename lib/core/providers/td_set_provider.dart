import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/pusher_service.dart';
import 'auth_provider.dart';

/// Global Language & Currency Provider (TD Set)
///
/// Fetches global exchange rates and supported languages.
/// Stores the user's personal language and currency preference.
class TdSetProvider extends ChangeNotifier {
  static const _prefLang = 'td_language';
  static const _prefCurrency = 'td_currency';

  // User Preferences
  String _language = 'en';
  String _currency = 'USDT';

  // Global Config from Super Admin
  List<String> _availableLanguages = ['en'];
  Map<String, double> _exchangeRates = {'USDT': 1.0};
  
  bool _isLoading = false;

  String get language => _language;
  String get currency => _currency;
  List<String> get availableLanguages => _availableLanguages;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoading => _isLoading;

  /// Get the current live exchange rate for the user's chosen currency
  double get currentExchangeRate {
    return _exchangeRates[_currency] ?? 1.0;
  }

  /// Format a base amount (e.g. USDT) into the user's currency with the live rate
  String formatCurrency(double baseAmount) {
    final converted = baseAmount * currentExchangeRate;
    return '$currencySymbol${converted.toStringAsFixed(2)}';
  }

  /// Returns the currency symbol for display (e.g., '৳' for BDT, '$' for USDT)
  String get currencySymbol {
    switch (_currency) {
      case 'BDT': return '৳';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'USDT':
      case 'USD':
      default: return '\$';
    }
  }

  /// Returns a human-readable currency label
  String get currencyLabel {
    switch (_currency) {
      case 'BDT': return 'BDT (Bangladeshi Taka)';
      case 'USDT': return 'USDT (US Dollar Tether)';
      default: return _currency;
    }
  }

  /// Returns a human-readable language label
  String get languageLabel {
    switch (_language) {
      case 'bn': return 'বাংলা (Bengali)';
      case 'en': default: return 'English';
    }
  }

  TdSetProvider() {
    _loadFromCache();
    _fetchConfigFromServer();
    _listenToPusher();
  }

  /// Load last persisted values from SharedPreferences immediately
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_prefLang);
      final curr = prefs.getString(_prefCurrency);
      if (lang != null) _language = lang;
      if (curr != null) _currency = curr;
      notifyListeners();
    } catch (e) {
      log('TdSet: Cache read error — $e');
    }
  }

  /// Fetch global config from the public `/td-set` endpoint
  Future<void> _fetchConfigFromServer() async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = '${AppConfig.baseUrl}/td-set';
      final res = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _availableLanguages = List<String>.from(data['languages'] ?? ['en']);
        _exchangeRates = Map<String, double>.from(
            (data['exchange_rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
        );
        log('TdSet: Fetched global config. Rates: $_exchangeRates');
        notifyListeners();
      }
    } catch (e) {
      log('TdSet: Server config fetch error — $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change the user's preference and sync with the backend
  Future<void> updateUserPreference(String lang, String curr, AuthProvider authProvider) async {
    _language = lang;
    _currency = curr;
    notifyListeners();
    
    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLang, lang);
      await prefs.setString(_prefCurrency, curr);
    } catch (e) {}

    // Sync to backend if logged in
    if (authProvider.isAuthenticated) {
      try {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/user/td-set'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authProvider.token}',
          },
          body: jsonEncode({
            'language': lang,
            'currency': curr,
          })
        );
      } catch (e) {
        log('TdSet: Failed to sync preference to backend — $e');
      }
    }
  }

  /// Subscribe to Pusher real-time updates for instant global config propagation
  void _listenToPusher() {
    PusherService().addListener(_onPusherEvent);
  }

  void _onPusherEvent(dynamic event) {
    try {
      if (event.eventName != 'data.updated') return;
      final dynamic rawData = event.data;
      final Map<String, dynamic> data = rawData is String
          ? Map<String, dynamic>.from(jsonDecode(rawData))
          : Map<String, dynamic>.from(rawData as Map);

      if (data['type'] == 'td_config_updated') {
        _availableLanguages = List<String>.from(data['languages'] ?? ['en']);
        _exchangeRates = Map<String, double>.from(
            (data['exchange_rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
        );
        log('TdSet: Real-time config update received. Rates: $_exchangeRates');
        notifyListeners();
      }
    } catch (e) {
      log('TdSet: Pusher event parse error — $e');
    }
  }

  Future<void> refresh() => _fetchConfigFromServer();

  @override
  void dispose() {
    PusherService().removeListener(_onPusherEvent);
    super.dispose();
  }
}
