import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _watchPathKey = 'watch_path';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _watchPath = "C:\\Grabadora_Virtual";

  ThemeMode get themeMode => _themeMode;
  String get watchPath => _watchPath;

  SettingsService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final themeStr = _prefs.getString(_themeKey);
    if (themeStr == 'light') _themeMode = ThemeMode.light;
    if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    
    final path = _prefs.getString(_watchPathKey);
    if (path != null) _watchPath = path;
    
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    
    await _prefs.setString(_themeKey, modeStr);
    notifyListeners();
  }

  Future<void> updateWatchPath(String path) async {
    _watchPath = path;
    await _prefs.setString(_watchPathKey, path);
    notifyListeners();
  }
}
