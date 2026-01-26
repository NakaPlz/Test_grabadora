
import 'dart:async';
import 'package:record/record.dart';
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
    return await _audioRecorder.hasPermission();
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
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
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
