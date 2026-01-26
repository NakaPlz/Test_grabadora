import 'dart:convert';
import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required String id,
    required String localPath,
    String? remoteUrl,
    required RecordingStatus status,
    required String transcript,
    required String summary,
    required String mindMapCode,
    required List<String> tasks,
    bool isFavorite = false,
    bool isDeleted = false,
    required DateTime createdAt,
  }) : super(
          id: id,
          localPath: localPath,
          remoteUrl: remoteUrl,
          status: status,
          transcript: transcript,
          summary: summary,
          mindMapCode: mindMapCode,
          tasks: tasks,
          isFavorite: isFavorite,
          isDeleted: isDeleted,
          createdAt: createdAt,
        );

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    // Parse tasks_json string if present, otherwise empty list
    List<String> parsedTasks = [];
    if (json['tasks_json'] != null) {
      try {
        parsedTasks = List<String>.from(jsonDecode(json['tasks_json']));
      } catch (e) {
        // Fallback or ignore
      }
    }

    return RecordingModel(
      id: json['id'],
      localPath: json['local_path'],
      remoteUrl: json['remote_url'],
      status: RecordingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RecordingStatus.pending,
      ),
      transcript: json['transcript'] ?? '',
      summary: json['summary'] ?? '',
      mindMapCode: json['mind_map_code'] ?? '',
      tasks: parsedTasks,
      isFavorite: json['is_favorite'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'remoteUrl': remoteUrl,
      'status': status.toString().split('.').last,
      'transcript': transcript,
      'summary': summary,
      'mindMapCode': mindMapCode,
      'tasks': tasks,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
