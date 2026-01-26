import '../entities/collection.dart';

abstract class CollectionRepository {
  Future<List<Collection>> getCollections();
  Future<Collection> createCollection(String name);
  Future<void> deleteCollection(int id);
  Future<Collection> addRecordingToCollection(int collectionId, String recordingId);
  Future<Collection> removeRecordingFromCollection(int collectionId, String recordingId);
}
