
import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/services/recorder_service.dart';
import '../../data/services/recorder_service_impl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class MobileRecordingSheet extends StatefulWidget {
  final Function(String path) onRecordingFinished;

  const MobileRecordingSheet({super.key, required this.onRecordingFinished});

  @override
  State<MobileRecordingSheet> createState() => _MobileRecordingSheetState();
}

class _MobileRecordingSheetState extends State<MobileRecordingSheet> with SingleTickerProviderStateMixin {
  late RecorderService _recorderService;
  RecorderState _state = RecorderState.stopped;
  Duration _duration = Duration.zero;
  Timer? _timer;
  double _amplitude = -50.0;
  
  // Animation for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _recorderService = RecorderServiceImpl();
    
    // Animation setup
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 1)
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    _initRecorder();
  }
  
  Future<void> _initRecorder() async {
      // Listeners
      _recorderService.stateStream.listen((s) {
          if (mounted) setState(() => _state = s);
      });
      
      _recorderService.amplitudeStream.listen((amp) {
          if (mounted) setState(() => _amplitude = amp);
      });

      // Error Listener
      _recorderService.errorStream.listen((error) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(error),
                 backgroundColor: Colors.red,
             ));
          }
      });
      
      // Auto-start (ask permission first)
      await _startRecording();
  }

  Future<void> _startRecording() async {
      // Check permission (Skip on Desktop windows as permission_handler might not support it fully)
      if (!Platform.isWindows) {
          final status = await Permission.microphone.request();
          if (status != PermissionStatus.granted) {
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permiso de micrófono denegado")));
                  Navigator.pop(context);
              }
              return;
          }
      }
      
      // Get path
      final dir = await getApplicationDocumentsDirectory();
      // Ensure folder exists
      final recordingsDir = Directory("${dir.path}/Recordings"); 
      if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
      }
      
      // Use .wav for better compatibility (matching service impl)
      final fileName = "recording_${const Uuid().v4()}.wav";
      final path = "${recordingsDir.path}/$fileName";
      
      await _recorderService.start(path);
      _startTimer();
  }
  
  void _startTimer() {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (mounted) setState(() => _duration += const Duration(seconds: 1));
      });
  }
  
  void _stopTimer() {
      _timer?.cancel();
  }

  Future<void> _stopRecording() async {
      _stopTimer();
      final path = await _recorderService.stop();
      if (path != null && mounted) {
          widget.onRecordingFinished(path);
          Navigator.pop(context);
      }
  }

  Future<void> _togglePause() async {
      if (_state == RecorderState.recording) {
          _stopTimer();
          await _recorderService.pause();
      } else if (_state == RecorderState.paused) {
          _startTimer();
          await _recorderService.resume();
      }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorderService.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    
    return Container(
       height: 350,
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
           color: Theme.of(context).scaffoldBackgroundColor,
           borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
       ),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
             const Text("Grabando...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 32),
             
             // Time & Visualizer
             Stack(
                alignment: Alignment.center,
                children: [
                    // Pulse Ring (Visualizer simpler for MVP)
                    ScaleTransition(
                        scale: _state == RecorderState.recording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withOpacity(0.1),
                            ),
                        ),
                    ),
                    Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                            fontSize: 48, 
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                    ),
                ],
             ),
             
             const SizedBox(height: 48),
             
             // Controls
             Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                     // Cancel
                     IconButton(
                         onPressed: () => Navigator.pop(context), // Cancel discards? Or we should delete?
                         icon: const Icon(Icons.close, color: Colors.grey, size: 32),
                     ),
                     const SizedBox(width: 32),
                     
                     // Stop (Save)
                     GestureDetector(
                         onTap: _stopRecording,
                         child: Container(
                             width: 72, height: 72,
                             decoration: BoxDecoration(
                                 color: primary,
                                 shape: BoxShape.circle,
                                 boxShadow: [
                                     BoxShadow(color: primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))
                                 ]
                             ),
                             child: const Icon(Icons.stop_rounded, color: Colors.white, size: 40),
                         ),
                     ),
                     
                     const SizedBox(width: 32),
                     
                     // Pause
                     IconButton(
                         onPressed: _togglePause,
                         icon: Icon(
                            _state == RecorderState.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, 
                            size: 32
                         ),
                         color: Theme.of(context).iconTheme.color,
                     ),
                 ],
             )
         ],
       ),
    );
  }
}
