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
          builder: (context, widget) {
            // Global Error Handling Logic
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              bool isDebug = false;
              assert(() {
                isDebug = true;
                return true;
              }());

              if (isDebug) {
                return ErrorWidget(errorDetails.exception);
              }

              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 80, color: Colors.deepPurple.shade300),
                      const SizedBox(height: 16),
                      const Text("¡Ups! Algo salió mal",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "Ha ocurrido un error inesperado. Por favor reinicia la aplicación.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            };
            return widget ?? const SizedBox();
          },
          home: SplashPage(settingsService: settingsService),
        );
      },
    );
  }
}
