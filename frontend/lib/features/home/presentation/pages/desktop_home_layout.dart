import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../domain/entities/recording.dart';
import '../../../../features/recordings/presentation/pages/recording_detail_page.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/recording_list_panel.dart';
import '../widgets/audio_player_footer.dart';
import '../../../../features/collections/presentation/widgets/collections_panel.dart';
import '../../../../features/settings/presentation/widgets/settings_panel.dart';
import '../../../../domain/entities/collection.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../features/recordings/presentation/pages/mobile_recording_sheet.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/toast_service.dart';

class DesktopHomeLayout extends StatefulWidget {
  final List<Recording> recordings;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final Function(Recording) onToggleFavorite;
  final List<Collection> collections;
  final Function(String name) onCreateCollection;
  final Function(int collectionId, String recordingId)
      onAddRecordingToCollection;
  final SettingsService? settingsService;
  final SidebarSection currentSection;
  final ValueChanged<SidebarSection> onSectionChanged;
  final Function(Recording) onRestoreRecording;
  final Function(Recording) onDeletePermanent;
  final Function(Recording) onDelete;
  final Function(String)? onNewRecording;

  const DesktopHomeLayout({
    super.key,
    required this.recordings,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onLogout,
    required this.onSync,
    required this.onUpload,
    required this.onToggleFavorite,
    required this.collections,
    required this.onCreateCollection,
    required this.onAddRecordingToCollection,
    this.settingsService,
    required this.currentSection,
    required this.onSectionChanged,
    required this.onRestoreRecording,
    required this.onDeletePermanent,
    required this.onDelete,
    this.onNewRecording,
  });

  @override
  State<DesktopHomeLayout> createState() => _DesktopHomeLayoutState();
}

class _DesktopHomeLayoutState extends State<DesktopHomeLayout> {
  Recording? _selectedRecording;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  String? _lastPlayedRecordingId;
  Collection? _selectedCollection;

  @override
  void didUpdateWidget(DesktopHomeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected recording is no longer in the list (e.g. deleted), clear selection
    if (_selectedRecording != null) {
      final found =
          widget.recordings.any((r) => r.id == _selectedRecording!.id);
      if (!found) {
        setState(() {
          _selectedRecording = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSectionChanged(SidebarSection section) {
    if (section != SidebarSection.collections) {
      _selectedCollection = null;
    }
    widget.onSectionChanged(section);
  }

  List<Recording> _getFilteredRecordings() {
    if (widget.currentSection == SidebarSection.favorites) {
      return widget.recordings.where((r) => r.isFavorite).toList();
    }
    if (widget.currentSection == SidebarSection.collections) {
      if (_selectedCollection != null) {
        return _selectedCollection!.recordings;
      }
      return []; // Not used when showing CollectionsPanel
    }
    // Trash logic handles fetching, so widget.recordings IS the trash list if section is trash
    if (widget.currentSection == SidebarSection.trash) {
      return widget.recordings;
    }
    return widget.recordings;
  }

  Future<void> _playPause() async {
    if (_selectedRecording == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        // If it's the same recording and we already have a position, just resume
        if (_lastPlayedRecordingId == _selectedRecording!.id && _position > Duration.zero) {
           await _audioPlayer.resume();
           return;
        }

        Source urlSource;
        // 1. Try Local File
        if (await File(_selectedRecording!.localPath).exists()) {
          print("Desktop: Playing local file: ${_selectedRecording!.localPath}");
          urlSource = DeviceFileSource(_selectedRecording!.localPath);
        } else {
          // 2. Fallback to Remote
          String url = _selectedRecording!.remoteUrl ?? "";
          if (url.isEmpty) {
             print("Desktop: No remoteUrl available for ${_selectedRecording!.id}");
             return;
          }

          if (!url.startsWith("http")) {
            url = "${ApiConstants.baseUrl}/$url";
          }
          
          // Ensure valid URL encoding (especially for spaces in filenames)
          url = url.replaceAll('\\', '/');
          url = Uri.encodeFull(url);
          
          print("Desktop: Playing remote file: $url");
          urlSource = UrlSource(url);
        }

        await _audioPlayer.setVolume(_volume);
        await _audioPlayer.setPlaybackRate(_speed);
        await _audioPlayer.play(urlSource);
        
        setState(() {
          _lastPlayedRecordingId = _selectedRecording!.id;
        });
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, "Error reproduciendo audio: $e");
        }
      }
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
    setState(() {
      _volume = volume;
    });
  }

  Future<void> _toggleSpeed() async {
    double newSpeed = 1.0;
    if (_speed == 1.0)
      newSpeed = 1.5;
    else if (_speed == 1.5)
      newSpeed = 2.0;
    else if (_speed == 2.0)
      newSpeed = 0.5;
    else
      newSpeed = 1.0;

    await _audioPlayer.setPlaybackRate(newSpeed);
    setState(() {
      _speed = newSpeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecordings = _getFilteredRecordings();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 1. Sidebar
                AppSidebar(
                  onNewRecording: () {
                    showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Container(
                                  width: 400,
                                  height: 400,
                                  // Wrap with Scaffold/Material to ensure theme
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: MobileRecordingSheet(
                                    onRecordingFinished: (path) {
                                      if (widget.onNewRecording != null) {
                                        widget.onNewRecording!(path);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ));
                  },
                  onSync: widget.onSync,
                  onUpload: widget.onUpload,
                  onLogout: widget.onLogout,
                  currentSection: widget.currentSection,
                  onSectionChanged: _onSectionChanged,
                ),
                const VerticalDivider(width: 1),

                // 2. Middle List Panel
                Expanded(
                  flex: 4,
                  child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (widget.currentSection == SidebarSection.collections &&
                              _selectedCollection == null)
                          ? CollectionsPanel(
                              collections: widget.collections,
                              onCollectionSelected: (collection) {
                                setState(() {
                                  _selectedCollection = collection;
                                });
                              },
                              onCreateCollection: widget.onCreateCollection,
                            )
                          : widget.currentSection == SidebarSection.settings &&
                                  widget.settingsService != null
                              ? SettingsPanel(
                                  settingsService: widget.settingsService!)
                              : RecordingListPanel(
                                  recordings: filteredRecordings,
                                  selectedRecording: _selectedRecording,
                                  errorMessage: widget.errorMessage,
                                  onRefresh: widget.onRefresh,
                                  onRecordingSelected: (recording) {
                                    setState(() {
                                      _selectedRecording = recording;
                                    });
                                  },
                                  onToggleFavorite: widget.onToggleFavorite,
                                  onAddToCollection: _showAddToCollectionDialog,
                                  currentSection: widget.currentSection,
                                  onRestore: widget.onRestoreRecording,
                                  onDeletePermanent: widget.onDeletePermanent,
                                ),
                ),
                const VerticalDivider(width: 1),

                // 3. Right Detail Panel
                Expanded(
                  flex: 6,
                  child: _selectedRecording == null
                      ? _buildEmptyState()
                      : _buildDetailPanel(),
                ),
              ],
            ),
          ),

          // 4. Persistent Footer
          AudioPlayerFooter(
            isPlaying: _isPlaying,
            duration: _duration,
            position: _position,
            onPlayPause: _playPause,
            onSeek: _seek,
            title: _selectedRecording?.title,
            volume: _volume,
            speed: _speed,
            onVolumeChanged: _setVolume,
            onSpeedChanged: _toggleSpeed,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          const Text("Selecciona una grabación para ver los detalles"),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    return RecordingDetailPage(
      key: ValueKey(_selectedRecording!.id),
      recording: _selectedRecording!,
      onPlayPause: _playPause,
      isPlaying: _isPlaying,
      onDelete: () {
        if (widget.currentSection == SidebarSection.trash) {
          widget.onDeletePermanent(_selectedRecording!);
        } else {
          widget.onDelete(_selectedRecording!);
        }
        // Selection clear handled by didUpdateWidget or explicitly here
        setState(() {
          _selectedRecording = null;
        });
      },
    );
  }

  void _showAddToCollectionDialog(Recording recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Añadir a Colección"),
        content: SizedBox(
          width: double.maxFinite,
          child: widget.collections.isEmpty
              ? const Text("No tienes colecciones. Crea una primero.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.collections.length,
                  itemBuilder: (context, index) {
                    final collection = widget.collections[index];
                    return ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: Text(collection.name),
                      onTap: () {
                        widget.onAddRecordingToCollection(
                            collection.id, recording.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
        ],
      ),
    );
  }
}
