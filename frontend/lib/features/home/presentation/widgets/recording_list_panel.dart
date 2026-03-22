import 'package:flutter/material.dart';
import '../../../../domain/entities/recording.dart';
import 'app_sidebar.dart';

class RecordingListPanel extends StatelessWidget {
  final List<Recording> recordings;
  final Recording? selectedRecording;
  final ValueChanged<Recording> onRecordingSelected;
  final ValueChanged<Recording>? onToggleFavorite;
  final ValueChanged<Recording>? onAddToCollection;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const RecordingListPanel({
    super.key,
    required this.recordings,
    required this.selectedRecording,
    required this.onRecordingSelected,
    this.onToggleFavorite,
    this.onAddToCollection,
    this.errorMessage,
    required this.onRefresh,
    this.currentSection = SidebarSection.all,
    this.onRestore,
    this.onDeletePermanent,
  });

  final SidebarSection currentSection;
  final ValueChanged<Recording>? onRestore;
  final ValueChanged<Recording>? onDeletePermanent;

// ...


  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.orange),
            const SizedBox(height: 8),
            Text("Error: $errorMessage", style: const TextStyle(fontSize: 12)),
            TextButton(onPressed: onRefresh, child: const Text("Retry"))
          ],
        ),
      );
    }
    
    if (recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(
              "No hay grabaciones",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                "Recientes",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list))
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.separated(
            itemCount: recordings.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final recording = recordings[index];
              final isSelected = selectedRecording == recording;
              
              // Alternating Color Logic
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final rowColor = isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : (index % 2 != 0 
                      ? (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02))
                      : Colors.transparent);
              
              // Date mock
              final dateStr = "Oct 25, 2023"; // TODO: Use real date
              
              return Material(
                color: rowColor,
                child: InkWell(
                  onTap: () => onRecordingSelected(recording),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                recording.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                            if (currentSection == SidebarSection.trash) ...[
                                IconButton(
                                  icon: const Icon(Icons.restore),
                                  onPressed: () => onRestore?.call(recording),
                                  tooltip: "Restaurar",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () => onDeletePermanent?.call(recording),
                                  tooltip: "Eliminar definitivamente",
                                ),
                            ] else ...[
                                if (onToggleFavorite != null)
                                    IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                            recording.isFavorite ? Icons.star : Icons.star_border,
                                            size: 20,
                                            color: recording.isFavorite ? Colors.amber : Colors.grey,
                                        ),
                                        onPressed: () => onToggleFavorite!(recording),
                                    ),
                                if (onAddToCollection != null)
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.playlist_add, size: 20, color: Theme.of(context).disabledColor),
                                      onPressed: () => onAddToCollection!(recording),
                                      tooltip: "Añadir a Colección",
                                    ),
                            ]
                          ],
                        ),
                        // ... existing date/status row
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                               "$dateStr • ${recording.status.toString().split('.').last.toUpperCase()}",
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                             ),
                             if (currentSection != SidebarSection.trash)
                               const Icon(Icons.chevron_right, size: 16, color: Colors.grey)
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
