import 'dart:io';
import '../../../../domain/entities/recording.dart';
import '../../../../domain/repositories/recording_repository.dart';
import '../datasources/recording_remote_datasource.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  final RecordingRemoteDataSource remoteDataSource;

  RecordingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Recording>> getRecordings({bool isDeleted = false}) async {
      return await remoteDataSource.getRecordings(isDeleted: isDeleted);
  }

  @override
  Future<Recording> getRecording(String id) async {
    return await remoteDataSource.getRecording(id);
  }

  @override
  Future<Recording> saveRecording(Recording recording) async {
    // For MVP sync, we create it via API
    return await remoteDataSource.createRecording(recording.localPath);
  }

  @override
  Future<void> uploadRecordingFile(String id, String path) async {
    await remoteDataSource.uploadRecordingFile(id, path);
  }

  @override
  Future<void> transcribeRecording(String id) async {
    await remoteDataSource.transcribeRecording(id);
  }

  @override
  Future<void> generateSummary(String id) async {
    await remoteDataSource.generateSummary(id);
  }

  @override
  Future<void> generateTasks(String id) async {
    await remoteDataSource.generateTasks(id);
  }

  @override
  Future<void> generateMindMap(String id) async {
    await remoteDataSource.generateMindMap(id);
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await remoteDataSource.updateRecording(id, {'is_favorite': isFavorite});
  }
  
  @override
  Future<void> deleteRecording(String id) async {
    // Soft Delete (Backend only)
    await remoteDataSource.deleteRecording(id);
  }

  @override
  Future<void> restoreRecording(String id) async {
    await remoteDataSource.restoreRecording(id);
  }

  @override
  Future<void> deleteRecordingPermanently(String id) async {
    // 1. Get recording details to find local path (if possible, though backend delete doesn't return it)
    // We try to fetch it first. Since it is 'deleted', normal getRecording might fail if we filtered?
    // Backend getRecording endpoint DOES NOT filter by is_deleted, so we can still fetch it.
    
    Recording? recording;
    try {
        recording = await remoteDataSource.getRecording(id);
    } catch(e) {
        print("Could not fetch recording details before permanent delete: $e");
    }

    // 2. Delete from Remote (Permanent)
    await remoteDataSource.deleteRecordingPermanently(id);
    
    // 3. Delete from Local Filesystem (Physical delete)
    if (recording != null) {
        try {
            final file = File(recording.localPath);
            if (await file.exists()) {
                await file.delete();
                print("Deleted local file: ${recording.localPath}");
            }
        } catch (e) {
            print("Error deleting local file: $e");
        }
    }
  }
}
