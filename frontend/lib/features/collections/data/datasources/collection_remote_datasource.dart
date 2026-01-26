import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../data/models/collection_model.dart';
import '../../../../domain/entities/collection.dart'; // To follow return type convention, though usually returns Models

class CollectionRemoteDataSource {
  final String baseUrl = 'http://127.0.0.1:8001';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CollectionRemoteDataSource();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<CollectionModel>> getCollections() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/collections/'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => CollectionModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load collections');
    }
  }

  Future<CollectionModel> createCollection(String name) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/collections/'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return CollectionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create collection');
    }
  }

  Future<void> deleteCollection(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/collections/$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete collection');
    }
  }

  Future<CollectionModel> addRecordingToCollection(int collectionId, String recordingId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/collections/$collectionId/recordings/$recordingId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return CollectionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add recording to collection');
    }
  }

  Future<CollectionModel> removeRecordingFromCollection(int collectionId, String recordingId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/collections/$collectionId/recordings/$recordingId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return CollectionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to remove recording from collection');
    }
  }
}
