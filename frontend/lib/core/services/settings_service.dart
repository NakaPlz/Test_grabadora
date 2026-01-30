import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _watchPathKey = 'watch_path';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _watchPath = "";

  ThemeMode get themeMode => _themeMode;
  String get watchPath => _watchPath;

  SettingsService() {
    // Initialize with a safe placeholder or wait for init()
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeStr = _prefs.getString(_themeKey);
    if (themeStr == 'light') _themeMode = ThemeMode.light;
    if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    
    final path = _prefs.getString(_watchPathKey);
    if (path != null && !(Platform.isAndroid && path.contains("C:\\"))) {
      _watchPath = path;
    } else {
      // Set default path if not already saved or if invalid (Windows path on Android)
      if (Platform.isWindows) {
        _watchPath = "C:\\Grabadora_Virtual";
      } else {
         final directory = await getApplicationDocumentsDirectory();
         _watchPath = directory.path;
         // Consider saving this valid default immediately to prefs? 
         // For now, just setting it in memory is safer until user confirms.
      }
    }
    
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
