import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../domain/entities/recording.dart';
import '../../../../domain/repositories/recording_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../recordings/data/datasources/recording_remote_datasource.dart';
import '../../../recordings/data/repositories/recording_repository_impl.dart';
import '../../../../domain/entities/collection.dart';
import '../../../../domain/repositories/collection_repository.dart';
import '../../../collections/data/datasources/collection_remote_datasource.dart';
import '../../../collections/data/repositories/collection_repository_impl.dart';
import '../../../sync/domain/services/sync_service.dart';
import '../../../sync/data/datasources/local_file_datasource.dart';
import 'dart:io'; 
import '../../../recordings/presentation/pages/mobile_recording_sheet.dart';
import 'mobile_trash_page.dart'; // Import New Page
import '../../../../features/recordings/presentation/pages/recording_detail_page.dart';
import '../../../../core/presentation/widgets/responsive_layout.dart';
import 'desktop_home_layout.dart';
import 'mobile_home_layout.dart';
import '../widgets/app_sidebar.dart';
import '../../../../core/services/settings_service.dart';
import '../../../settings/presentation/widgets/settings_panel.dart';

class HomePage extends StatefulWidget {
  final SettingsService? settingsService;
  
  const HomePage({super.key, this.settingsService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecordingRepository _recordingRepository;
  late CollectionRepository _collectionRepository;
  late SyncService _syncService;
  
  // Data State
  List<Recording> _recordings = [];
  List<Collection> _collections = [];
  bool _isLoading = true;
  String? _errorMessage;
  SidebarSection _currentSection = SidebarSection.all;

  // Audio State (Lifted Up)
  final AudioPlayer _audioPlayer = AudioPlayer();
  Recording? _currentRecording;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  // Audio Control Methods
  Future<void> _playRecording(Recording recording) async {
    try {
      if (_currentRecording?.id != recording.id) {
        // Stop previous if different
        await _audioPlayer.stop();
        setState(() {
          _currentRecording = recording;
          _position = Duration.zero;
          // Optimistic: We'll get duration shortly
        });

        String url = recording.remoteUrl ?? "";
        if (!url.startsWith("http")) {
           url = "http://127.0.0.1:8001/$url";
           url = url.replaceAll('\\', '/');
        }
        await _audioPlayer.play(UrlSource(url));
      } else {
        // Resume
        if (_position >= _duration || _position >= (_duration - const Duration(seconds: 1))) {
             await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error al reproducir: $e"))
         );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _audioPlayer.pause();
  }
  
  Future<void> _seekRecording(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void initState() {
    super.initState();
    // Dependency Injection (Manual for MVP)
    _recordingRepository = RecordingRepositoryImpl(
      remoteDataSource: RecordingRemoteDataSource(
        client: http.Client(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _collectionRepository = CollectionRepositoryImpl(
      remoteDataSource: CollectionRemoteDataSource(),
    );
    _syncService = SyncService(
      repository: _recordingRepository, 
      localFileDataSource: LocalFileDataSource()
    );

    // Audio Listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    // Cleanup on finish
    _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
            setState(() {
                _isPlaying = false;
                _position = Duration.zero;
            });
        }
    });

    _fetchRecordings();
    _fetchCollections();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchCollections() async {
    try {
      final collections = await _collectionRepository.getCollections();
      setState(() {
        _collections = collections;
      });
    } catch (e) {
      print("Error fetching collections: $e");
    }
  }

  Future<void> _createCollection(String name) async {
      try {
          await _collectionRepository.createCollection(name);
          _fetchCollections(); // Refresh list
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Colección creada con éxito")),
          );
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al crear colección: $e")),
          );
      }
  }

  Future<void> _addRecordingToCollection(int collectionId, String recordingId) async {
      try {
          await _collectionRepository.addRecordingToCollection(collectionId, recordingId);
          _fetchCollections(); 
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Grabación añadida a la colección")),
          );
      } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al añadir: $e")),
          );
      }
  }

  Future<void> _fetchRecordings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isTrash = _currentSection == SidebarSection.trash;
      final recordings = await _recordingRepository.getRecordings(isDeleted: isTrash);
      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    } on AuthException catch (_) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Tu sesión ha expirado. Por favor ingresa nuevamente.")),
             );
             _logout(); 
        }
    } catch (e) {
      if (mounted) {
        setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
         });
      }
    }
  }

  Future<void> _sync() async {
    final watchPath = widget.settingsService?.watchPath ?? "C:\\Grabadora_Virtual";
    
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sincronizando: Buscando en $watchPath ..."))
    );
    
    // Use the simulator path (Ensure this exists on user's machine)
    await _syncService.syncFolder(watchPath);
    
    // Refresh list
    await _fetchRecordings();
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Sincronización finalizada 📂"))
       );
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => LoginPage(settingsService: widget.settingsService)),
         (route) => false, // Remove all previous routes
       );
    }
  }


  Future<void> _toggleFavorite(Recording recording) async {
    // 1. Optimistic Update
    final newStatus = !recording.isFavorite;
    final updatedList = _recordings.map((r) {
        if (r.id == recording.id) {
           // Create copy with new status (Need copyWith method or manual)
           // Since Recording is immutable, I need to verify if I have copyWith. 
           // I don't recall generating it. I'll do manual instantiation.
           return _manualCopyWith(r, newStatus);
        }
        return r;
    }).toList();

    setState(() {
        _recordings = updatedList;
    });

    // 2. API Call
    try {
        await _recordingRepository.toggleFavorite(recording.id, newStatus);
    } catch (e) {
        // Revert on error
        print("Error toggling favorite: $e");
        _fetchRecordings(); // Refresh to ensure truth
    }
  }

  // Helper because we didn't use freezed/copyWith yet
  Recording _manualCopyWith(Recording r, bool isFavorite) {
      // Assuming RecordingModel is what we are using, but the list is List<Recording>.
      // Entities don't usually have copyWith unless generated.
      // I'll create a simple constructor call.
      return Recording(
          id: r.id,
          localPath: r.localPath,
          remoteUrl: r.remoteUrl,
          status: r.status,
          transcript: r.transcript,
          summary: r.summary,
          mindMapCode: r.mindMapCode,
          tasks: r.tasks,
          isFavorite: isFavorite,
          createdAt: r.createdAt,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      desktopBody: DesktopHomeLayout(
        recordings: _recordings,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRefresh: _fetchRecordings,
        onSync: _sync,
        onLogout: _logout,
        onToggleFavorite: _toggleFavorite,
        collections: _collections,
        onCreateCollection: _createCollection,
        onAddRecordingToCollection: _addRecordingToCollection,
        settingsService: widget.settingsService,
        currentSection: _currentSection,
        onSectionChanged: (section) {
            setState(() {
               _currentSection = section;
            });
            _fetchRecordings(); 
        },
        onRestoreRecording: (recording) async {
            try {
                await _recordingRepository.restoreRecording(recording.id);
                _fetchRecordings(); // Refresh
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Grabación restaurada")),
                );
            } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al restaurar: $e")),
                );
            }
        },
        onDeletePermanent: (recording) async {
            final confirm = await showDialog<bool>(
              context: context, 
              builder: (ctx) => AlertDialog(
                  title: const Text("¿Eliminar definitivamente?"),
                  content: const Text("Esta acción no se puede deshacer. El archivo se borrará permanentemente."),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar")),
                  ],
              )
            );
            
            if (confirm == true) {
               try {
                  await _recordingRepository.deleteRecordingPermanently(recording.id);
                  _fetchRecordings();
                  if (!mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Grabación eliminada permanentemente")),
                  );
               } catch (e) {
                   if (!mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al eliminar: $e")),
                  );
               }
            }
        },
        onDelete: _deleteRecording,
        onNewRecording: _handleNewRecording,
      ),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
      try {
          await _recordingRepository.deleteRecording(recording.id);
          _fetchRecordings();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Grabación movida a la papelera")),
          );
      } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al eliminar: $e")),
          );
      }
  }

  int _currentMobileTab = 0;

  Widget _buildMobileLayout() {
    // Filter recordings based on tab
    List<Recording> displayedRecordings = _recordings;
    if (_currentMobileTab == 1) { // Favorites
      displayedRecordings = _recordings.where((r) => r.isFavorite == true).toList();
    } 
    // Tab 2 is Mic (Action)
    // Tab 3 is Collections (Navigation?)
    // Tab 4 is Settings (Navigation?)

    return MobileHomeLayout(
      recordings: displayedRecordings,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _fetchRecordings,
      onRecordingTap: (recording, {int initialTab = 0}) async {
         final result = await Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => RecordingDetailPage(
                    recording: recording,
                    initialTabIndex: initialTab,
                    // Unified Audio Logic
                    forceMobileLayout: true,
                    isPlaying: _currentRecording?.id == recording.id && _isPlaying,
                    currentPosition: _currentRecording?.id == recording.id ? _position : Duration.zero,
                    totalDuration: _currentRecording?.id == recording.id ? _duration : Duration.zero,
                    // PASS PERMANENT STREAMS from the player instance
                    positionStream: _audioPlayer.onPositionChanged,
                    durationStream: _audioPlayer.onDurationChanged,
                    playerStateStream: _audioPlayer.onPlayerStateChanged, // NEW: Pass state stream
                    onPlayPause: () { 
                        if (_currentRecording?.id == recording.id) {
                          if (_isPlaying) _pauseRecording(); else _playRecording(recording);
                        } else {
                          _playRecording(recording);
                        }
                    },
                    onSeek: (pos) {
                        _audioPlayer.seek(Duration(seconds: pos.toInt()));
                    },
                    playbackSpeed: _currentRecording?.id == recording.id ? _playbackSpeed : 1.0,
                    onSpeedChanged: (speed) {
                       _audioPlayer.setPlaybackRate(speed);
                       setState(() {
                          _playbackSpeed = speed;
                       });
                    },
                    onShare: () {
                        // TODO: Implement share
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compartir no implementado")));
                    },
                    onToggleFavorite: () => _toggleFavorite(recording),
                 ),
               ),
             );
             if (result == true) {
                 _fetchRecordings();
             }
      },
      onToggleFavorite: _toggleFavorite,
      onDelete: _deleteRecording,
      onSync: _sync,
      onLogout: _logout,
      onOpenTrash: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => MobileTrashPage(recordingRepository: _recordingRepository)
          )).then((_) => _fetchRecordings()); // Refresh on return
      },
      currentNavIndex: _currentMobileTab,
      onNewRecording: _handleNewRecording,
      onNavIndexChanged: (index) {
          if (index == 2) {
             // Open Recorder
             showModalBottomSheet(
                context: context, 
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => MobileRecordingSheet(
                    onRecordingFinished: (path) {
                        _handleNewRecording(path);
                    },
                )
             );
          } else if (index == 4) {
             // Open Settings
             Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                appBar: AppBar(title: const Text("Ajustes")),
                body: SettingsPanel(settingsService: widget.settingsService ?? SettingsService()),
             )));
          } else {
             setState(() {
                _currentMobileTab = index;
             });
          }
      },
      // Audio Props
      currentRecording: _currentRecording,
      isPlaying: _isPlaying,
      position: _position,
      duration: _duration,
      onPlay: _playRecording,
      onPause: _pauseRecording,
      
      // Collections Props
      collections: _collections,
      onCreateCollection: _createCollection,
      onDeleteCollection: (c) {
           // TODO: Implement delete collection logic
      },
      onTapCollection: (collection) {
           // Navigate to collection details (Future work)
           // For MVP, maybe filter list?
           // Let's just show a snackbar for now or filter recordings
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Colección: ${collection.name}")));
      },
    );
  }

  Future<void> _handleNewRecording(String path) async {
      // Move recording to Watch Path to simulate Sync
      final watchPath = widget.settingsService?.watchPath ?? "C:\\Grabadora_Virtual";
      try {
         // Fix: Handle both separators
         final normalizedPath = path.replaceAll('/', '\\'); 
         final fileName = normalizedPath.split('\\').last;
         
         final destDir = Directory(watchPath);
         if (!await destDir.exists()) {
             await destDir.create(recursive: true);
         }
         final destPath = "${destDir.path}\\$fileName";
         
         await File(path).copy(destPath);
         await File(path).delete(); // Cleanup temp
         
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Grabación guardada y sincronizada")));
         }
         
         // Trigger sync
         _sync();
         
      } catch (e) {
         print("Error moving recording: $e");
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error guardando grabación: $e")));
         }
      }
  }
}
