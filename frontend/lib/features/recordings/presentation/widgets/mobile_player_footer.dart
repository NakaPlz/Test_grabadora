import 'package:flutter/material.dart';

class MobilePlayerFooter extends StatelessWidget {
  final String title;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Function(double) onSeek;
  final VoidCallback? onRewind;
  final VoidCallback? onForward;
  final VoidCallback? onSpeedPressed; // New
  final VoidCallback? onSharePressed; // New
  final VoidCallback? onFavoritePressed; // New
  final VoidCallback? onMorePressed; // New
  final bool isFavorite; // New
  final double playbackSpeed; // New

  const MobilePlayerFooter({
    super.key,
    required this.title,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
    this.onRewind,
    this.onForward,
    this.onSpeedPressed,
    this.onSharePressed,
    this.onFavoritePressed,
    this.onMorePressed,
    this.isFavorite = false,
    this.playbackSpeed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
           top: BorderSide(
             color: isDark ? Colors.white10 : Colors.black12,
           ),
        ),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 20,
             offset: const Offset(0, -5),
           )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       "REPRODUCIENDO",
                       style: TextStyle(
                         color: primary,
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.0,
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       title,
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ],
                 ),
               ),
                Row(
                  children: [
                    IconButton(
                        onPressed: onSharePressed,
                        icon: Icon(Icons.share_outlined, color: Theme.of(context).iconTheme.color, size: 20),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: onFavoritePressed,
                        icon: Icon(
                            isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isFavorite ? const Color(0xFF7C3AED) : Theme.of(context).iconTheme.color,
                            size: 20
                        ),
                    ),
                  ],
               )
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          // Using standard Slider for now customized
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: primary,
              inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[200],
              thumbColor: primary,
            ),
            child: Slider(
              value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
              max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
              onChanged: onSeek,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position), style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                Text(_formatDuration(duration), style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Controls
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                // Speed Button
                GestureDetector(
                  onTap: onSpeedPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${playbackSpeed}x",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                
                // Play Controls
                Row(
                   children: [
                      IconButton(
                        onPressed: onRewind, 
                        icon: const Icon(Icons.replay_10_rounded, size: 28)
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onPlayPause,
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                             color: primary,
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: primary.withOpacity(0.4),
                                 blurRadius: 12,
                                 offset: const Offset(0, 4),
                               )
                             ]
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: onForward, 
                        icon: const Icon(Icons.forward_10_rounded, size: 28)
                      ),
                   ],
                ),
                
                // More Option
                IconButton(
                  onPressed: onMorePressed,
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                ),
             ],
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
