import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
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

    if (token != null && _isTokenValid(token)) {
        // Token exists and is valid, go to Home
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(settingsService: widget.settingsService)),
        );
    } else {
        // Token expired or does not exist, clear it just in case and go to Login
        await _storage.delete(key: 'auth_token');
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginPage(settingsService: widget.settingsService)),
        );
    }
  }

  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payloadString = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = json.decode(payloadString);

      if (payload['exp'] == null) return false;
      final expInt = int.tryParse(payload['exp'].toString()) ?? 0;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expInt * 1000);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return false;
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
            SizedBox(height: 16),
            Text("HILO", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
