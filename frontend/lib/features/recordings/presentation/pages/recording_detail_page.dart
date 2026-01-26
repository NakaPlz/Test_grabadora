import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../domain/entities/recording.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/repositories/recording_repository_impl.dart';
import '../../data/datasources/recording_remote_datasource.dart';
import '../../../../domain/repositories/recording_repository.dart';

import 'package:webview_windows/webview_windows.dart';
import '../widgets/processing_status_card.dart';
import '../widgets/mobile_player_footer.dart';

class RecordingDetailPage extends StatefulWidget {
  final Recording recording;
  final VoidCallback? onPlayPause;
  final Function(double)? onSeek;
  final Function(double)? onSpeedChanged;
  final VoidCallback? onShare;
  final VoidCallback? onToggleFavorite;
  final bool isPlaying;
  final double playbackSpeed;
  final int initialTabIndex;
  final bool forceMobileLayout;
  
  // External Audio Props
  final Duration currentPosition;
  final Duration totalDuration;
  final Stream<Duration>? positionStream;
  final Stream<Duration>? durationStream;
  final Stream<PlayerState>? playerStateStream;

  const RecordingDetailPage({
    super.key, 
    required this.recording,
    this.onPlayPause,
    this.onSeek,
    this.onSpeedChanged,
    this.onShare,
    this.onToggleFavorite,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.onDelete,
    this.initialTabIndex = 0,
    this.forceMobileLayout = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.positionStream,
    this.durationStream,
    this.playerStateStream,
  });

  final VoidCallback? onDelete;

  @override
  State<RecordingDetailPage> createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  late AudioPlayer _audioPlayer;
  late Recording _recording;
  late RecordingRepository _repository;
  
  // WebView Controller
  final  _webViewController = WebviewController();
  bool _isWebviewInitialized = false;

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _recording = widget.recording;
    
    // Initialize local speed from widget or default
    _playbackSpeed = widget.playbackSpeed;

    // REFRESH DATA
    _repository = RecordingRepositoryImpl(
      remoteDataSource: RecordingRemoteDataSource(
        client: http.Client(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _refreshRecording();

    if (widget.onPlayPause == null) {
        // Internal player setup
        _audioPlayer.onPlayerStateChanged.listen((state) {
            if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
        });
        _audioPlayer.onDurationChanged.listen((d) {
            if (mounted) setState(() => _duration = d);
        });
        _audioPlayer.onPositionChanged.listen((p) {
             if (mounted) setState(() => _position = p);
        });
        _audioPlayer.onPlayerComplete.listen((event) {
             if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
        });
    } else {
        // External player setup - Listener for State Changes
        if (widget.playerStateStream != null) {
            widget.playerStateStream!.listen((state) {
                 if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
            });
        }
        
        // Also listen to Duration changes from external player if available
        if (widget.durationStream != null) {
            widget.durationStream!.listen((d) {
                 if (mounted) setState(() => _duration = d);
            });
        }

        // We can also listen to position to update _position local state, 
        // which helps if we want to default to it instead of StreamBuilder sometimes
        if (widget.positionStream != null) {
            widget.positionStream!.listen((p) {
                 if (mounted) setState(() => _position = p);
            });
        }
        
        // Initialize state from widget props
        _isPlaying = widget.isPlaying;
        _duration = widget.totalDuration;
        _position = widget.currentPosition;
    }
    
    // Initialize Webview
    _initWebview();
  }
  
  Future<void> _initWebview() async {
      try {
          await _webViewController.initialize();
          if (mounted) {
              setState(() {
                  _isWebviewInitialized = true;
              });
              _loadMindMapContent();
          }
      } catch (e) {
          print("Error initializing webview: $e");
      }
  }
  
  void _loadMindMapContent() {
      if (!_isWebviewInitialized) return;
      if (_recording.mindMapCode.isEmpty) return;
      
      final mermaidCode = _recording.mindMapCode;
      // HTML Template with Mermaid
      final htmlContent = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f5f5f5; }
    .mermaid { width: 100%; text-align: center; }
  </style>
</head>
<body>
  <div class="mermaid">
    $mermaidCode
  </div>
  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
    mermaid.initialize({ startOnLoad: true });
  </script>
</body>
</html>
      """;
      
      _webViewController.loadStringContent(htmlContent);
  }

  // ... (Polling logic and other methods unchanged) ...



  // TIMER FOR POLLING
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (widget.onPlayPause == null) {
       _audioPlayer.dispose();
    }
    _webViewController.dispose(); // Dispose Webview
    super.dispose();
  }

  // POLLING LOGIC
  void _startPolling() {
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          if (!mounted) {
              timer.cancel();
              return;
          }
          await _refreshRecording();
          // Stop polling if completed or error
          if (_recording.status == RecordingStatus.completed || _recording.status == RecordingStatus.pending) {
              timer.cancel();
          }
      });
  }

  Future<void> _refreshRecording() async {
    try {
      final fresh = await _repository.getRecording(_recording.id);
      if (mounted) {
         bool statusChanged = _recording.status != fresh.status;
         bool mindMapChanged = _recording.mindMapCode != fresh.mindMapCode;
         
        setState(() {
          _recording = fresh;
        });
        
        // Reload mind map if new content arrived
        if (mindMapChanged && _recording.mindMapCode.isNotEmpty) {
            _loadMindMapContent();
        }
        
        // Auto-start polling if we find it transcribing
        if (_recording.status == RecordingStatus.transcribing && (_pollingTimer == null || !_pollingTimer!.isActive)) {
            _startPolling();
        }
      }
    } catch (e) {
      print("Error refreshing recording: $e");
    }
  }

// ... (Rest of existing methods) ...

  Future<void> _requestTranscription() async {
      try {
          setState(() {
              // Optimistic update to show loading immediately
              // We could also add a separate loading flag
          });
          
          await _repository.transcribeRecording(_recording.id);
          
          // Refresh state to confirm 'transcribing' status
          await _refreshRecording();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transcripción iniciada...")),
          );
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error iniciando transcripción: $e")),
          );
      }
  }

  // ... (Audio player methods unchanged) ...

  // HELPER METHODS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      String url = _recording.remoteUrl ?? "";
      if (!url.startsWith("http")) {
         url = "http://127.0.0.1:8001/$url";
         url = url.replaceAll('\\', '/');
      }
      
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error reproduciendo audio: $e")),
            );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Grabación"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (widget.onDelete != null) {
          widget.onDelete!();
      } else {
          // Mobile / Standalone behavior
          try {
            await _repository.deleteRecording(_recording.id);
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Grabación eliminada")),
               );
               Navigator.pop(context, true); // Return to list
            }
          } catch (e) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al eliminar: $e")),
               );
            }
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If forced mobile, or no play callback (standalone default), use mobile
    if (widget.forceMobileLayout || widget.onPlayPause == null) {
        return _buildMobileLayout();
    }
    return _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_recording.localPath.split('\\').last),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.description), text: "Transcripción"),
              Tab(icon: Icon(Icons.summarize), text: "Resumen"),
              Tab(icon: Icon(Icons.check_circle), text: "Tareas"),
              Tab(icon: Icon(Icons.psychology), text: "Mapa Mental"),
            ],
          ),
        ),
        body: Column(
          children: [
            // PLAYER CONTROLS (Desktop External)
            Container(
              color: Colors.deepPurple.shade50,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Reproducción en Desktop", style: TextStyle(color: Colors.deepPurple.shade300, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onPlayPause,
                          icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
                          label: Text(widget.isPlaying ? "PAUSAR" : "REPRODUCIR"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),

            // PROCESSING CARD
            if (_recording.status != RecordingStatus.completed)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ProcessingStatusCard(
                    recording: _recording,
                    onProcess: _requestTranscription,
                  ),
                ),

            // TABS CONTENT
            Expanded(
              child: TabBarView(
                children: [
                  _buildTranscriptTab(),
                  _buildSummaryTab(),
                  _buildTasksTab(),
                  _buildMindMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
     return DefaultTabController(
       length: 4,
       initialIndex: widget.initialTabIndex,
       child: Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         appBar: AppBar(
           elevation: 0,
           backgroundColor: Theme.of(context).primaryColor,
           foregroundColor: Colors.white,
           title: Text(
             _recording.localPath.split('\\').last.split('/').last,
             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
           ),
           leading: IconButton(
             icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
             onPressed: () => Navigator.pop(context),
           ),
           actions: [
             IconButton(
               icon: const Icon(Icons.delete_outline_rounded),
               onPressed: () => _confirmDelete(context),
             ),
           ],
           bottom: PreferredSize(
             preferredSize: const Size.fromHeight(60),
             child: Container(
               height: 60,
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: const TabBar(
                 isScrollable: true,
                 indicatorColor: Colors.white,
                 indicatorWeight: 3,
                 labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                 unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                 labelColor: Colors.white,
                 unselectedLabelColor: Colors.white60,
                 tabs: [
                    _CustomTab(icon: Icons.description_rounded, text: "Transcripción"),
                    _CustomTab(icon: Icons.article_rounded, text: "Resumen"),
                    _CustomTab(icon: Icons.check_circle_outline_rounded, text: "Tareas"),
                    _CustomTab(icon: Icons.psychology_rounded, text: "Mapa Mental"),
                 ],
               ),
             ),
           ),
         ),
         body: Column(
           children: [
             // Processing Status (If applicable)
             if (_recording.status != RecordingStatus.completed)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ProcessingStatusCard(
                    recording: _recording,
                    onProcess: _requestTranscription,
                  ),
                ),
                
             // Content
             Expanded(
               child: TabBarView(
                 children: [
                   _buildTranscriptTab(),
                   _buildSummaryTab(),
                   _buildTasksTab(),
                   _buildMindMapTab(),
                 ],
               ),
             ),
             
             // Footer Player
             StreamBuilder<Duration>(
               stream: widget.positionStream, // External stream
               initialData: widget.currentPosition, // Initial position
               builder: (context, snapshot) {
                 final currentPos = widget.onPlayPause != null ? (snapshot.data ?? Duration.zero) : _position;
                 final currentDur = _duration;
                 final isPlayingState = _isPlaying;

                 return MobilePlayerFooter(
                   title: _recording.localPath.split('\\').last.split('/').last,
                   
                   position: currentPos,
                   duration: currentDur,
                   isPlaying: isPlayingState,
                   playbackSpeed: _playbackSpeed,
                   isFavorite: _recording.isFavorite, // Note: We might need to listen to updates if this changes outside
                   
                   onPlayPause: widget.onPlayPause ?? _playPause,
                   
                   onSeek: (val) {
                      if (widget.onPlayPause == null) {
                          _audioPlayer.seek(Duration(seconds: val.toInt()));
                      } else if (widget.onSeek != null) {
                          widget.onSeek!(val);
                      }
                   },
                    onRewind: () {
                      if (widget.onPlayPause == null) {
                          final newPos = _position - const Duration(seconds: 10);
                          _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                      } else if (widget.onSeek != null) {
                          // Calculate new position using local synced _position
                           final newPos = _position - const Duration(seconds: 10);
                           widget.onSeek!(newPos.inSeconds.toDouble() < 0 ? 0 : newPos.inSeconds.toDouble());
                      }
                   },
                   onForward: () {
                     if (widget.onPlayPause == null) {
                        final newPos = _position + const Duration(seconds: 10);
                        _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                     } else if (widget.onSeek != null) {
                          // Calculate new position using local synced _position
                          final newPos = _position + const Duration(seconds: 10);
                          final maxDur = widget.totalDuration.inSeconds.toDouble() > 0 ? widget.totalDuration.inSeconds.toDouble() : _duration.inSeconds.toDouble();
                          final target = newPos.inSeconds.toDouble();
                          widget.onSeek!(maxDur > 0 && target > maxDur ? maxDur : target);
                     }
                   },
                   
                   onSpeedPressed: () {
                       // Cycle speeds: 1.0 -> 1.5 -> 2.0 -> 0.5 -> 1.0
                       final current = _playbackSpeed;
                       double next = 1.0;
                       if (current == 1.0) next = 1.5;
                       else if (current == 1.5) next = 2.0;
                       else if (current == 2.0) next = 0.5;
                       else next = 1.0;

                       // Update local state IMMEDIATELY for UI responsiveness
                       setState(() { _playbackSpeed = next; });

                       if (widget.onPlayPause == null) {
                           _audioPlayer.setPlaybackRate(next);
                       } else if (widget.onSpeedChanged != null) {
                           widget.onSpeedChanged!(next);
                       }
                   },
                   
                   onSharePressed: widget.onShare ?? () {
                       // Default share if not provided (though for now, just print or show snackbar)
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compartir no implementado")));
                   },
                   
                   onFavoritePressed: widget.onToggleFavorite,

                   onMorePressed: () {
                       // Show modal bottom sheet
                       showModalBottomSheet(
                           context: context, 
                           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                           builder: (ctx) => Container(
                               padding: const EdgeInsets.all(24),
                               child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                       ListTile(
                                           leading: const Icon(Icons.info_outline),
                                           title: const Text("Detalles del archivo"),
                                           onTap: () {},
                                       ),
                                       ListTile(
                                           leading: const Icon(Icons.download_rounded),
                                           title: const Text("Descargar audio"),
                                           onTap: () {},
                                       ),
                                   ],
                               ),
                           )
                       );
                   },
                 );
               }
             )
           ],
         ),
       ),
     );
  }

  // ... (Previous tabs unchanged) ...

  Widget _buildTranscriptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                const Text(
                    "Transcripción Completa",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _recording.transcript.isNotEmpty 
                ? _recording.transcript 
                : (_recording.status == RecordingStatus.transcribing 
                    ? "La IA está procesando tu audio. Esto puede tardar unos momentos..."
                    : "La transcripción aún no está disponible."),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumen Ejecutivo",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _recording.summary.isNotEmpty 
                    ? _recording.summary 
                    : "El resumen aún no está disponible.",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _recording.tasks.length + 1,
        itemBuilder: (context, index) {
            if (index == 0) {
                return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                        "Tareas Detectadas",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                );
            }
            final task = _recording.tasks[index - 1];
            return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                    leading: const Icon(Icons.check_box_outline_blank, color: Colors.deepPurple),
                    title: Text(task),
                ),
            );
        },
    );
  }

  Widget _buildMindMapTab() {
    if (_recording.status != RecordingStatus.completed) {
         return const Center(child: Text("El mapa mental se generará al finalizar la transcripción.", style: TextStyle(color: Colors.grey)));
    }
    if (_recording.mindMapCode.isEmpty) {
         return const Center(child: Text("No se pudo generar un mapa mental para este audio.", style: TextStyle(color: Colors.grey)));
    }
    if (!_isWebviewInitialized) {
        return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
        child: Webview(_webViewController),
      ),
    );
  }
}

class _CustomTab extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CustomTab({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
