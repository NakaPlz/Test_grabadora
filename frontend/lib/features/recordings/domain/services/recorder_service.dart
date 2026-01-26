
import 'dart:async';

abstract class RecorderService {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<String?> stop();
  Future<void> pause();
  Future<void> resume();
  Stream<double> get amplitudeStream;
  Stream<RecorderState> get stateStream;
  Stream<String> get errorStream;
  Future<void> dispose();
}

enum RecorderState {
  stopped,
  recording,
  paused,
}
