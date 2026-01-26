abstract class DiscoveryService {
  /// Stream of detection events (true = detected, false = disconnected)
  Stream<bool> get detectionStream;

  /// Check current status
  Future<bool> isConnected();

  /// Sync files from device
  Future<void> syncFiles();
}
