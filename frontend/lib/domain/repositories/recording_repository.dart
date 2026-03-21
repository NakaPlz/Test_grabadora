import '../entities/recording.dart';

abstract class RecordingRepository {
  Future<List<Recording>> getRecordings({bool isDeleted = false});
  Future<Recording> getRecording(String id);
  Future<Recording> saveRecording(Recording recording);
  Future<void> uploadRecordingFile(String id, String path);
  Future<void> transcribeRecording(String id);
  Future<void> generateSummary(String id);
  Future<void> generateTasks(String id);
  Future<void> generateMindMap(String id);
  Future<void> toggleFavorite(String id, bool isFavorite);
  Future<void> deleteRecording(String id);
  Future<void> restoreRecording(String id);
  Future<void> deleteRecordingPermanently(String id);
}
