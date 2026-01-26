import 'dart:async';
import '../../domain/services/discovery_service.dart';

class MockDiscoveryService implements DiscoveryService {
  final _controller = StreamController<bool>.broadcast();

  MockDiscoveryService() {
    // Simulate connection after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _controller.add(true);
      print("🔌 [MOCK] Grabadora conectada (Simulación)");
    });
  }

  @override
  Stream<bool> get detectionStream => _controller.stream;

  @override
  Future<bool> isConnected() async {
    return true; // Always return true for testing commands
  }

  @override
  Future<void> syncFiles() async {
    print("🔄 [MOCK] Sincronizando archivos desde la grabadora...");
    await Future.delayed(const Duration(seconds: 2));
    print("✅ [MOCK] Sincronización completada.");
  }
}
