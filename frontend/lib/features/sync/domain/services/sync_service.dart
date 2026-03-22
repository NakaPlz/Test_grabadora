import '../../../../domain/entities/recording.dart';
import '../../../../domain/repositories/recording_repository.dart';
import '../../data/datasources/local_file_datasource.dart';

class SyncService {
  final RecordingRepository repository;
  final LocalFileDataSource localFileDataSource;

  SyncService({
    required this.repository,
    required this.localFileDataSource,
  });

  Future<void> syncFolder(String folderPath) async {
    final files = await localFileDataSource.scanDirectory(folderPath);
    final activeRecordings = await repository.getRecordings();
    final deletedRecordings = await repository.getRecordings(isDeleted: true);
    final remoteRecordings = [...activeRecordings, ...deletedRecordings];

    for (var file in files) {
      // Simple duplicate check by path
      // Note: In real world, use hash or filename check if path varies
      bool exists = remoteRecordings.any((r) => r.localPath == file.path);
      
      if (!exists) {
        print("Syncing new file: ${file.path}");
        // Create Recording (Metadata)
        final newRec = Recording(
          id: '', // Ignored by backend on create
          title: file.path.split('\\').last.split('/').last,
          localPath: file.path, 
          status: RecordingStatus.pending,
          transcript: '',
          summary: '',
          mindMapCode: '',
          tasks: [],
          createdAt: DateTime.now()
        );

        try {
          // 1. Create Metadata
          final createdRec = await repository.saveRecording(newRec);
          
          // 2. Upload Binary
          print("Uploading binary for: ${createdRec.id}");
          await repository.uploadRecordingFile(createdRec.id, file.path);
          print("Upload complete: ${file.path}");
          
        } catch (e) {
          print("Failed to sync file ${file.path}: $e");
        }
      } else {
        print("File already synced: ${file.path}");
      }
    }
  }
}
