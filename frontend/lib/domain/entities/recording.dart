enum RecordingStatus { pending, uploaded, transcribing, completed }

class Recording {
  final String id;
  final String localPath;
  final String? remoteUrl;
  final RecordingStatus status;
  final String transcript;
  final String summary;
  final String mindMapCode;
  final List<String> tasks; // Simply strings for now, can be objects later
  final bool isFavorite;
  final bool isDeleted;
  final DateTime createdAt;

  const Recording({
    required this.id,
    required this.localPath,
    this.remoteUrl,
    required this.status,
    required this.transcript,
    required this.summary,
    required this.mindMapCode,
    required this.tasks,
    this.isFavorite = false,
    this.isDeleted = false,
    required this.createdAt,
  });
}
