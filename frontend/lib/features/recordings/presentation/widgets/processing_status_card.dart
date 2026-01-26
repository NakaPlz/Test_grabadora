import 'package:flutter/material.dart';
import '../../../../domain/entities/recording.dart';

class ProcessingStatusCard extends StatelessWidget {
  final Recording recording;
  final VoidCallback onProcess;

  const ProcessingStatusCard({
    super.key,
    required this.recording,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProcessing = recording.status == RecordingStatus.transcribing;
    final isCompleted = recording.status == RecordingStatus.completed;
    final isUploaded = recording.status == RecordingStatus.uploaded;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  "Procesamiento IA",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isProcessing) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 20),
            _buildStepRow(context, "Transcripción Audio a Texto", isCompleted || isProcessing, isCompleted),
            const SizedBox(height: 12),
            _buildStepRow(context, "Generación de Resumen", isCompleted || isProcessing, isCompleted),
            const SizedBox(height: 12),
            _buildStepRow(context, "Extracción de Tareas", isCompleted || isProcessing, isCompleted),
            const SizedBox(height: 12),
            _buildStepRow(context, "Creación de Mapa Mental", isCompleted || isProcessing, isCompleted),
            
            const SizedBox(height: 24),
            
            if (isUploaded)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onProcess,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Iniciar Procesamiento"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
              
            if (isProcessing)
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                     const SizedBox(width: 12),
                     const Expanded(child: Text("La IA está analizando tu grabación. Esto puede tomar unos minutos.")),
                   ],
                 ),
               ),
               
             if (isCompleted)
                Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.green.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: const Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.check_circle, size: 20, color: Colors.green),
                     SizedBox(width: 8),
                     Text("Análisis Completado", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, String title, bool isEnabled, bool isDone) {
      final color = isEnabled 
        ? (isDone ? Colors.green : Theme.of(context).colorScheme.primary)
        : Theme.of(context).disabledColor;
      
      return Row(
        children: [
          Icon(
            isDone ? Icons.check_box : (isEnabled ? Icons.indeterminate_check_box : Icons.check_box_outline_blank),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isEnabled ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).disabledColor,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
  }
}
