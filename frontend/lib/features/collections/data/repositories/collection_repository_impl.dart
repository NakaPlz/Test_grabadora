import '../../../../domain/entities/collection.dart';
import '../../../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Collection>> getCollections() async {
    return await remoteDataSource.getCollections();
  }

  @override
  Future<Collection> createCollection(String name) async {
    return await remoteDataSource.createCollection(name);
  }

  @override
  Future<void> deleteCollection(int id) async {
    await remoteDataSource.deleteCollection(id);
  }

  @override
  Future<Collection> addRecordingToCollection(int collectionId, String recordingId) async {
    return await remoteDataSource.addRecordingToCollection(collectionId, recordingId);
  }

  @override
  Future<Collection> removeRecordingFromCollection(int collectionId, String recordingId) async {
    return await remoteDataSource.removeRecordingFromCollection(collectionId, recordingId);
  }
}
