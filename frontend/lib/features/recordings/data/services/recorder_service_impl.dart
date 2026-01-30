import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/services/recorder_service.dart';

class RecorderServiceImpl implements RecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Stream Controllers
  final _amplitudeController = StreamController<double>.broadcast();
  final _stateController = StreamController<RecorderState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Timer? _amplitudeTimer;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Stream<RecorderState> get stateStream => _stateController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  RecorderServiceImpl() {
    _stateController.add(RecorderState.stopped);
  }

  @override
  Future<bool> hasPermission() async {
    // 1. Check Microphone Permission
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) return false;
    }

    // 2. Check Storage Permission
    // We only need to request this if we are NOT using the app's internal private storage.
    // However, keeping it simple:

    if (Platform.isAndroid) {
      // Check if SDK is 33+ (Android 13) where WRITE_EXTERNAL_STORAGE is deprecated
      // Determining SDK version in pure Dart is tricky without device_info_plus,
      // but permission_handler handles SDK checks internally.

      // If Permission.storage.request() is called on Android 13, it returns denied.
      // We should rely on Permission.photos / audio / video if needed, OR just no permission for App Docs.

      // CRITICAL UPDATE: We assume we are saving to ApplicationDocumentsDirectory.
      // In that case, NO storage permission is required.

      /* 
          We verify if we need it. For now, we will SKIP blocking on storage permission error 
          because often it's a false positive on modern Android if we stick to internal paths.
       */

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        // Try to request, but don't fail if denied, assuming we have a valid internal path.
        // This fixes the "User stuck on permission loop" for Android 13+
        await Permission.storage.request();
      }
    }

    return true;
  }

  @override
  Future<void> start(String path) async {
    try {
      if (await hasPermission()) {
        // Use standard config, prefer PCM16BIT / WAV for Windows compatibility
        /* 
           Note: file extension must match encoder. 
           If path ends with .wav, record package should infer wav.
           But explicitly setting encoder is safer.
        */
        const config = RecordConfig(encoder: AudioEncoder.wav);

        await _audioRecorder.start(config, path: path);
        _stateController.add(RecorderState.recording);
        _startAmplitudeTimer();
      } else {
        _errorController.add("Permiso de micrófono no concedido.");
      }
    } catch (e) {
      print("Error starting recorder: $e");
      _errorController.add("Error al iniciar grabación: $e");
    }
  }

  @override
  Future<String?> stop() async {
    _stopAmplitudeTimer();
    final path = await _audioRecorder.stop();
    _stateController.add(RecorderState.stopped);
    return path;
  }

  @override
  Future<void> pause() async {
    await _audioRecorder.pause();
    _stopAmplitudeTimer();
    _stateController.add(RecorderState.paused);
  }

  @override
  Future<void> resume() async {
    await _audioRecorder.resume();
    _startAmplitudeTimer();
    _stateController.add(RecorderState.recording);
  }

  void _startAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final amp = await _audioRecorder.getAmplitude();
      _amplitudeController.add(amp.current);
    });
  }

  void _stopAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  @override
  Future<void> dispose() async {
    _stopAmplitudeTimer();
    _audioRecorder.dispose();
    _amplitudeController.close();
    _stateController.close();
  }
}
