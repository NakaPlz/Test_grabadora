import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/pages/splash_page.dart';
import 'core/theme/app_theme.dart';

import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.init();
  
  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  
  const MyApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsService,
      builder: (context, child) {
        return MaterialApp(
          title: 'AI Recorder Bridge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsService.themeMode,
          home: SplashPage(settingsService: settingsService),
        );
      },
    );
  }
}
