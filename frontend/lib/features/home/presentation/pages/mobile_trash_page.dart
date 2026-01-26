
import 'package:flutter/material.dart';
import '../../../../domain/entities/recording.dart';
import '../../../../domain/repositories/recording_repository.dart';
import '../../../../features/recordings/presentation/pages/recording_detail_page.dart';
import '../widgets/mobile_recording_card.dart';

class MobileTrashPage extends StatefulWidget {
  final RecordingRepository recordingRepository;

  const MobileTrashPage({super.key, required this.recordingRepository});

  @override
  State<MobileTrashPage> createState() => _MobileTrashPageState();
}

class _MobileTrashPageState extends State<MobileTrashPage> {
  List<Recording> _trashRecordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrash();
  }

  Future<void> _fetchTrash() async {
    setState(() => _isLoading = true);
    try {
      final recordings = await widget.recordingRepository.getRecordings(isDeleted: true);
      setState(() {
        _trashRecordings = recordings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _restore(Recording recording) async {
    try {
      await widget.recordingRepository.restoreRecording(recording.id);
      _fetchTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Grabación restaurada")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _deletePermanently(Recording recording) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar definitivamente?"),
        content: const Text("No podrás recuperar esta grabación."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.recordingRepository.deleteRecordingPermanently(recording.id);
        _fetchTrash();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Papelera"),
        actions: [
            IconButton(onPressed: _fetchTrash, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashRecordings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("La papelera está vacía", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashRecordings.length,
                  itemBuilder: (context, index) {
                    final recording = _trashRecordings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        leading: const Icon(Icons.audio_file, color: Colors.grey),
                        title: Text(
                            recording.localPath.split('\\').last.split('/').last,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(recording.createdAt.toString().split('.')[0]),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                IconButton(
                                    icon: const Icon(Icons.restore, color: Colors.green),
                                    onPressed: () => _restore(recording),
                                    tooltip: "Restaurar",
                                ),
                                IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    onPressed: () => _deletePermanently(recording),
                                    tooltip: "Eliminar definitivamente",
                                ),
                            ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
