import '../../domain/entities/collection.dart';
import 'recording_model.dart';
import '../../domain/entities/recording.dart';

class CollectionModel extends Collection {
  CollectionModel({
    required int id,
    required String name,
    required int userId,
    required DateTime createdAt,
    List<Recording> recordings = const [],
  }) : super(
          id: id,
          name: name,
          userId: userId,
          createdAt: createdAt,
          recordings: recordings,
        );

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      recordings: json['recordings'] != null
          ? (json['recordings'] as List)
              .map((i) => RecordingModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      // 'recordings': recordings.map((e) => (e as RecordingModel).toJson()).toList(), // Usually we don't send full recordings back on update
    };
  }
}
