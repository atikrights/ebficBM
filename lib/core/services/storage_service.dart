import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService extends ChangeNotifier {
  static const String _keyIsFirstRun = 'is_first_run';
  static const String _keyHasAgreed = 'has_agreed';
  static const String _keyDataPath = 'data_storage_path';
  static const String _keyUserName = 'user_name';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  bool get isFirstRun => _prefs.getBool(_keyIsFirstRun) ?? true;
  bool get hasAgreed => _prefs.getBool(_keyHasAgreed) ?? false;
  String? get dataPath => _prefs.getString(_keyDataPath);
  String? get userName => _prefs.getString(_keyUserName);

  Future<void> setFirstRunComplete() async {
    await _prefs.setBool(_keyIsFirstRun, false);
    notifyListeners();
  }

  Future<void> setAgreed(bool value) async {
    await _prefs.setBool(_keyHasAgreed, value);
    notifyListeners();
  }

  Future<void> setDataPath(String path) async {
    await _prefs.setString(_keyDataPath, path);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
    notifyListeners();
  }

  bool get isSetupComplete => !isFirstRun && hasAgreed;
}
