import 'recording.dart';

class Collection {
  final int id;
  final String name;
  final int userId;
  final DateTime createdAt;
  final List<Recording> recordings;

  Collection({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    this.recordings = const [],
  });
}
