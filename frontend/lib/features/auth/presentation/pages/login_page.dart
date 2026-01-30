import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'signup_page.dart';

import 'package:flutter/foundation.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/toast_service.dart';

class LoginPage extends StatefulWidget {
  final SettingsService? settingsService;

  const LoginPage({super.key, this.settingsService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Dependency Injection (Mock usage for MVP)
  // In a real app, use GetIt or Provider
  late AuthRepositoryImpl _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        client: http.Client(),
        storage: const FlutterSecureStorage(),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.login(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastService.showSuccess(context, 'Login Exitoso! 🚀');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomePage(settingsService: widget.settingsService)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Check for common error patterns
          final errorString = e.toString();
          if (errorString.contains("Failed to login")) {
            _errorMessage = "Usuario o contraseña incorrectos.";
          } else if (errorString.contains("verified")) {
            _errorMessage = "Tu cuenta no está verificada. Revisa tu correo.";
          } else {
            _errorMessage =
                "Error: $errorString"; // Show actual error for debugging
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_person,
                      size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  const Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Por favor ingresa tu correo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) => value!.isEmpty
                        ? 'Por favor ingresa tu contraseña'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('INICIAR SESIÓN',
                            style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                  const SizedBox(height: 24),
                  SelectableText(
                    "Debug Info:\nMode: ${kReleaseMode ? 'Release' : 'Debug'}\nAPI: ${ApiConstants.baseUrl}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.withOpacity(0.5), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
