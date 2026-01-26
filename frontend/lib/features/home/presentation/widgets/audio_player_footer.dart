import 'package:flutter/material.dart';

class AudioPlayerFooter extends StatelessWidget {
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final double volume;
  final double speed;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onSpeedChanged;
  final String? title;

  const AudioPlayerFooter({
    super.key,
    required this.isPlaying,
    required this.duration,
    required this.position,
    required this.onPlayPause,
    required this.onSeek,
    required this.volume,
    required this.speed,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    this.title,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Controls
          Row(
            children: [
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.skip_previous),
                color: theme.iconTheme.color,
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.skip_next),
                color: theme.iconTheme.color,
              ),
            ],
          ),
          
          const SizedBox(width: 32),
          
          // Progress & Waveform Area
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title ?? "Selecciona una grabación", 
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    Text(
                      "${_formatDuration(position)} / ${_formatDuration(duration)}", 
                      style: theme.textTheme.labelSmall
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Slider for progress
                SizedBox(
                  height: 24,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      onChanged: (val) {
                         onSeek(Duration(seconds: val.toInt()));
                      },
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.dividerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 32),
          
          // Extra Actions
          Row(
            children: [
               const Icon(Icons.volume_up, size: 20, color: Colors.grey),
               SizedBox(
                 width: 100,
                 child: SliderTheme(
                   data: SliderTheme.of(context).copyWith(
                     trackHeight: 2,
                     thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                     overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                   ),
                   child: Slider(
                     value: volume,
                     min: 0.0,
                     max: 1.0,
                     onChanged: onVolumeChanged,
                     activeColor: theme.colorScheme.primary,
                     inactiveColor: theme.dividerColor,
                   ),
                 ),
               ),
               const SizedBox(width: 16),
               ActionChip(
                 label: Text("${speed}x"),
                 onPressed: onSpeedChanged,
                 side: BorderSide.none,
                 backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                 labelStyle: TextStyle(
                   fontSize: 12, 
                   fontWeight: FontWeight.bold,
                   color: theme.textTheme.bodyMedium?.color,
                 ),
               ),
               const SizedBox(width: 8),
               IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
        ],
      ),
    );
  }
}
