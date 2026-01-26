import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../data/models/recording_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class RecordingRemoteDataSource {
  static const String baseUrl = 'http://127.0.0.1:8001'; // Port 8001
  final http.Client client;
  final FlutterSecureStorage storage;

  RecordingRemoteDataSource({
    required this.client,
    required this.storage,
  });

  Future<List<RecordingModel>> getRecordings({bool isDeleted = false}) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.get(
      Uri.parse('$baseUrl/recordings/?is_deleted=$isDeleted'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response, 'Failed to load recordings');
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => RecordingModel.fromJson(json)).toList();
  }

  Future<RecordingModel> getRecording(String id) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.get(
      Uri.parse('$baseUrl/recordings/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response, 'Failed to load recording');
    return RecordingModel.fromJson(json.decode(response.body));
  }

  Future<RecordingModel> createRecording(String localPath) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.post(
      Uri.parse('$baseUrl/recordings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'local_path': localPath,
        'status': 'pending',
      }),
    );

    _handleResponse(response, 'Failed to create recording');
    return RecordingModel.fromJson(json.decode(response.body));
  }

  Future<void> uploadRecordingFile(String recordingId, String filePath) async {
    final token = await storage.read(key: 'auth_token');
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/recordings/$recordingId/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var response = await request.send();

    if (response.statusCode != 200) {
       if (response.statusCode == 401) throw AuthException('Session expired');
       final respStr = await response.stream.bytesToString();
       throw Exception('Error ${response.statusCode}: Failed to upload file: $respStr');
    }
  }

  Future<void> transcribeRecording(String recordingId) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.post(
      Uri.parse('$baseUrl/recordings/$recordingId/transcribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response, 'Failed to start transcription');
  }

  Future<void> deleteRecording(String id) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.delete(
      Uri.parse('$baseUrl/recordings/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


    _handleResponse(response, 'Failed to delete recording');
  }

  Future<void> restoreRecording(String id) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.post(
      Uri.parse('$baseUrl/recordings/$id/restore'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response, 'Failed to restore recording');
  }

  Future<void> deleteRecordingPermanently(String id) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.delete(
      Uri.parse('$baseUrl/recordings/$id/permanent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response, 'Failed to delete recording permanently');
  }

  Future<RecordingModel> updateRecording(String id, Map<String, dynamic> updates) async {
    final token = await storage.read(key: 'auth_token');
    final response = await client.patch(
      Uri.parse('$baseUrl/recordings/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updates),
    );

    _handleResponse(response, 'Failed to update recording');
    return RecordingModel.fromJson(json.decode(response.body));
  }

  void _handleResponse(http.Response response, String errorMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else if (response.statusCode == 401) {
      throw AuthException('Session expired');
    } else {
      throw Exception('Error ${response.statusCode}: $errorMessage: ${response.body}');
    }
  }
}
