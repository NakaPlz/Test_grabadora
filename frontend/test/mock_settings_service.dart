import 'package:flutter/material.dart';
import 'package:frontend/core/services/settings_service.dart';

class MockSettingsService implements SettingsService {
  @override
  ThemeMode get themeMode => ThemeMode.system;

  @override
  String get watchPath => "";

  @override
  Future<void> init() async {}

  @override
  Future<void> updateThemeMode(ThemeMode mode) async {}

  @override
  Future<void> updateWatchPath(String path) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  bool get hasListeners => false;

  @override
  void notifyListeners() {}
}
