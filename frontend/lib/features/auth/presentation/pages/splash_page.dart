import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../features/home/presentation/pages/home_page.dart';
import 'login_page.dart';

import '../../../../core/services/settings_service.dart';

class SplashPage extends StatefulWidget {
  final SettingsService? settingsService; // Optional for now, but should be passed
  
  const SplashPage({super.key, this.settingsService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for better UX (optional)
    await Future.delayed(const Duration(seconds: 1));
    
    final token = await _storage.read(key: 'auth_token');
    
    if (!mounted) return;

    if (token != null) {
        // Token exists, go to Home
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(settingsService: widget.settingsService)),
        );
    } else {
        // No token, go to Login
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginPage(settingsService: widget.settingsService)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 80, color: Colors.deepPurple),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
