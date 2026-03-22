import 'package:flutter/material.dart';
import '../../../../domain/entities/recording.dart';
import '../../../../core/services/settings_service.dart';
import '../widgets/mobile_recording_card.dart';
import '../widgets/mobile_navigation_bar.dart';
import '../../../../features/collections/presentation/pages/mobile_collections_page.dart';

import '../../../../domain/entities/collection.dart'; // Ensure Imported

class MobileHomeLayout extends StatefulWidget {
  final List<Recording> recordings;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final Function(Recording, {int initialTab}) onRecordingTap;
  final Function(Recording) onToggleFavorite;
  final Function(Recording) onDelete;
  final VoidCallback onSync;
  final VoidCallback onLogout;
  final int currentNavIndex;
  final Function(int) onNavIndexChanged;
  
  // Audio Props
  final Recording? currentRecording;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Function(Recording) onPlay;
  final VoidCallback onPause;

  // Collections Props
  final List<Collection> collections;
  final Function(String) onCreateCollection;
  final Function(Collection) onDeleteCollection;
  final Function(Collection) onTapCollection; // Can mimic recording tap or show details
  final Function(String)? onNewRecording; // Path to new recording
  final VoidCallback? onOpenTrash; // New callback

  const MobileHomeLayout({
    super.key,
    required this.recordings,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onRecordingTap,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onSync,
    required this.onLogout,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.currentRecording,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    required this.onPlay,
    required this.onPause,
    this.collections = const [],
    this.onCreateCollection = _defaultCreateCollection,
    this.onDeleteCollection = _defaultDeleteCollection,
    this.onTapCollection = _defaultTapCollection,
    this.onNewRecording,
    this.onOpenTrash,
  });

  static dynamic _defaultCreateCollection(String s) {}
  static dynamic _defaultDeleteCollection(Collection c) {}
  static dynamic _defaultTapCollection(Collection c) {}

  @override
  State<MobileHomeLayout> createState() => _MobileHomeLayoutState();
}

class _MobileHomeLayoutState extends State<MobileHomeLayout> {
  final TextEditingController _searchController = TextEditingController();
  List<Recording> _filteredRecordings = [];

  @override
  void initState() {
    super.initState();
    _filteredRecordings = widget.recordings;
    _searchController.addListener(_filterRecordings);
  }

  @override
  void didUpdateWidget(covariant MobileHomeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordings != widget.recordings) {
      _filterRecordings();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecordings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecordings = widget.recordings;
      } else {
        _filteredRecordings = widget.recordings.where((rec) {
          final title = rec.title.toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  @override

  @override
  Widget build(BuildContext context) {
    // Determine Body Content
    Widget bodyContent;
    if (widget.currentNavIndex == 3) {
      bodyContent = MobileCollectionsPage(
        collections: widget.collections,
        isLoading: widget.isLoading,
        onCreateCollection: widget.onCreateCollection,
        onDeleteCollection: widget.onDeleteCollection,
        onTapCollection: widget.onTapCollection,
      );
    } else {
      bodyContent = GestureDetector(
             onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
             child: CustomScrollView(
              slivers: [
                // 1. Header with Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                    child: Column(
                      children: [
                             // Top Bar: Logo + Avatar
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Row(
                                   children: [
                                     Container(
                                       width: 32, height: 32,
                                       decoration: BoxDecoration(
                                         color: const Color(0xFF7C3AED), // Force Bridge AI Purple
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                       child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
                                     ),
                                     const SizedBox(width: 12),
                                     Text(
                                       "Bridge AI",
                                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                         fontSize: 20,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ],
                                 ),
                                 
                                 // ACTIONS: Sync + Trash + Avatar
                                 Row(
                                     children: [
                                         IconButton(
                                             onPressed: widget.onSync,
                                             icon: const Icon(Icons.sync),
                                             tooltip: "Sincronizar",
                                         ),
                                         IconButton(
                                             onPressed: () {
                                                 if (widget.onOpenTrash != null) widget.onOpenTrash!();
                                             },
                                             icon: const Icon(Icons.delete_sweep_outlined),
                                             tooltip: "Papelera",
                                         ),
                                         const SizedBox(width: 8),
                                         PopupMenuButton<String>(
                                           onSelected: (value) {
                                              if (value == 'logout') {
                                                 widget.onLogout();
                                              }
                                           },
                                           itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'logout',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.logout, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              )
                                           ],
                                           child: CircleAvatar(
                                             radius: 18,
                                             backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white10 : Colors.grey[200],
                                             child: Icon(Icons.person, size: 20, color: Theme.of(context).iconTheme.color),
                                           ),
                                         )
                                     ],
                                 )
                               ],
                             ),
                             const SizedBox(height: 24),
                             
                             // Search Bar
                         Row(
                           children: [
                             Expanded(
                               child: Container(
                                 height: 50,
                                 decoration: BoxDecoration(
                                   color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF161B2E) // Card Dark
                                      : const Color(0xFFF1F5F9), // Slate 100
                                   borderRadius: BorderRadius.circular(16),
                                 ),
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 child: Row(
                                   children: [
                                     Icon(Icons.search, color: Colors.grey[400]),
                                     const SizedBox(width: 12),
                                     Expanded(
                                       child: TextField(
                                         controller: _searchController,
                                         decoration: InputDecoration(
                                           border: InputBorder.none,
                                           hintText: "Buscar grabaciones...",
                                           hintStyle: TextStyle(color: Colors.grey[500]),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Container(
                               height: 50, width: 50,
                               decoration: BoxDecoration(
                                 color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF161B2E) 
                                      : const Color(0xFFF1F5F9),
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: Icon(Icons.tune_rounded, color: Colors.grey[500]),
                             )
                           ],
                         )
                      ],
                    ),
                  ),
                ),

                // 2. "Recientes" Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recientes", 
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Ver todas",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // 3. List
                if (widget.isLoading)
                   const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (widget.errorMessage != null)
                   SliverFillRemaining(child: Center(child: Text(widget.errorMessage!)))
                else if (_filteredRecordings.isEmpty)
                   SliverFillRemaining(
                     child: Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                           const SizedBox(height: 16),
                           Text(
                             _searchController.text.isEmpty 
                               ? "No hay grabaciones" 
                               : "No se encontraron resultados",
                             style: TextStyle(color: Colors.grey[500]),
                           ),
                         ],
                       )
                     )
                   )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recording = _filteredRecordings[index];
                          
                          // Calculate Alternating Color
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final Color? altColor = index % 2 != 0 
                            ? (isDark 
                                ? Colors.white.withOpacity(0.04) 
                                : Colors.black.withOpacity(0.03))
                            : null;

                          return MobileRecordingCard(
                            recording: recording,
                            onTap: () => widget.onRecordingTap(recording),
                            onToggleFavorite: () => widget.onToggleFavorite(recording),
                            backgroundColor: altColor,
                            onTranscriptionTap: () {
                               // Open detail with tab 0
                               widget.onRecordingTap(recording, initialTab: 0); 
                            },
                            onSummaryTap: () {
                               // Open detail with tab 1
                               widget.onRecordingTap(recording, initialTab: 1);
                            },
                          );
                        },
                        childCount: _filteredRecordings.length,
                      ),
                    ),
                  ),

                // Bottom Padding for Nav Bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // We use Stack to place Nav Bar at bottom over the content
      body: Stack(
        children: [
          // Main Content
          bodyContent,
          
          // Mini Player
          if (widget.currentRecording != null)
            Positioned(
              left: 16, right: 16, bottom: 85, // Above Nav Bar
              child: GestureDetector(
                onTap: () {
                   // Open Full Player Detail
                   widget.onRecordingTap(widget.currentRecording!);
                },
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1E293B) // Slate 800
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.music_note, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      
                      // Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentRecording!.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Progress bar
                            LinearProgressIndicator(
                              value: widget.duration.inSeconds > 0 
                                  ? widget.position.inSeconds / widget.duration.inSeconds 
                                  : 0,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                              minHeight: 2,
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Controls
                      IconButton(
                        icon: Icon(widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        onPressed: () {
                           if (widget.isPlaying) {
                             widget.onPause();
                           } else {
                             widget.onPlay(widget.currentRecording!);
                           }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),

          // Navigation Bar (Aligned to bottom)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: MobileNavigationBar(
              currentIndex: widget.currentNavIndex,
              onTap: widget.onNavIndexChanged,
            ),
          ),
        ],
      ),
    );
  }
}
