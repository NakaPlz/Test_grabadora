import 'package:flutter/material.dart';
import '../../../../domain/entities/collection.dart';

class MobileCollectionsPage extends StatefulWidget {
  final List<Collection> collections;
  final Function(String) onCreateCollection;
  final Function(Collection) onDeleteCollection; // Might need this later
  final Function(Collection) onTapCollection;
  final bool isLoading;

  const MobileCollectionsPage({
    super.key,
    required this.collections,
    required this.onCreateCollection,
    required this.onDeleteCollection,
    required this.onTapCollection,
    required this.isLoading,
  });

  @override
  State<MobileCollectionsPage> createState() => _MobileCollectionsPageState();
}

class _MobileCollectionsPageState extends State<MobileCollectionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Colecciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          )
        ],
      ),
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.collections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("No tienes colecciones", style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showCreateDialog,
                        child: const Text("Crear Nueva"),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.collections.length,
                  itemBuilder: (context, index) {
                    final collection = widget.collections[index];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Card(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.folder, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(collection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${collection.recordings.length} grabaciones"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onTapCollection(collection),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Colección"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nombre de la colección"),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onCreateCollection(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }
}
