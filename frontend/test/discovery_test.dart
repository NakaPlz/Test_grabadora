import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/infrastructure/discovery/mock_discovery_service.dart';

void main() {
  group('Discovery Service Tests', () {
    test('Mock service should emit connected state after delay', () async {
      print("🧪 Testing Discovery Service...");
      final service = MockDiscoveryService();
      
      print("   Waiting for detection stream...");
      final firstState = await service.detectionStream.first;
      
      expect(firstState, true);
      print("✅ Device Detected successfully!");
    });

    test('Sync files should complete', () async {
      final service = MockDiscoveryService();
      print("🧪 Testing File Sync...");
      
      await service.syncFiles();
      print("✅ File Sync completed.");
    });
  });
}
