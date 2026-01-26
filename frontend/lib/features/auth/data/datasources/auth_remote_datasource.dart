import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  // Use 127.0.0.1 for Windows/iOS simulator, 10.0.2.2 for Android Emulator
  // Since we target Windows Desktop:
  static const String baseUrl = 'http://127.0.0.1:8001';
  
  final http.Client client;
  final FlutterSecureStorage storage;

  AuthRemoteDataSource({required this.client, required this.storage});

  Future<String> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/token'),
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      await storage.write(key: 'auth_token', value: token);
      return token;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> signUp(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to sign up: ${response.body}');
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }
}
