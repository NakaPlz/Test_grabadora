import 'package:flutter/material.dart';
import '../../../../domain/entities/recording.dart';

class MobileRecordingCard extends StatelessWidget {
  final Recording recording;
  final VoidCallback onTap;
  final VoidCallback? onTranscriptionTap;
  final VoidCallback? onSummaryTap;
  final VoidCallback onToggleFavorite;

  const MobileRecordingCard({
    super.key,
    required this.recording,
    required this.onTap,
    required this.onToggleFavorite,
    this.onTranscriptionTap,
    this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Status Logic
    Color statusColor = Colors.grey;
    String statusText = "";
    Color statusBg = Colors.grey.withOpacity(0.1);

    if (recording.status == RecordingStatus.completed) {
      statusColor = const Color(0xFF16A34A); // Green 600
      statusBg = const Color(0xFFDCFCE7); // Green 100
      if (isDark) statusBg = const Color(0xFF14532D).withOpacity(0.3); // Darker Green
      statusText = "COMPLETADO";
    } else if (recording.status == RecordingStatus.uploaded || recording.status == RecordingStatus.transcribing) {
      statusColor = const Color(0xFF2563EB); // Blue 600
      statusBg = const Color(0xFFDBEAFE); // Blue 100
      if (isDark) statusBg = const Color(0xFF1E3A8A).withOpacity(0.3); // Darker Blue
      statusText = "PROCESANDO...";
    } else {
      statusText = "PENDIENTE";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          boxShadow: [
             BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row: Icon + Info + Star
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 / Slate 100
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.audiotrack_rounded,
                      color: Color(0xFF7C3AED), // Check consistency
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.localPath.split('\\').last.split('/').last, // Simple name extraction
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(recording.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // Favorite Icon
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      recording.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: recording.isFavorite 
                          ? const Color(0xFF7C3AED) // Hardcoded Purple to force update
                          : (isDark ? Colors.white70 : Colors.grey), // Brighter for dark mode
                      size: 28,
                    ),
                  ),
                ],
              ),

              // Action Buttons (Only if completed)
              if (recording.status == RecordingStatus.completed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.description_rounded,
                        label: "Transcripción",
                        color: const Color(0xFF7C3AED), // Explicit Purple
                        textColor: Colors.white,
                        onTap: onTranscriptionTap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.summarize_rounded,
                        label: "Resumen",
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        textColor: isDark ? Colors.white70 : Colors.black87,
                        onTap: onSummaryTap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Basic formatting. Use intl package in real app
    return "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
