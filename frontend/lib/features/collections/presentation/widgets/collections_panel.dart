import 'package:flutter/material.dart';
import '../../../../domain/entities/collection.dart';

class CollectionsPanel extends StatelessWidget {
  final List<Collection> collections;
  final Function(Collection) onCollectionSelected;
  final Function(String name) onCreateCollection;

  const CollectionsPanel({
    super.key,
    required this.collections,
    required this.onCollectionSelected,
    required this.onCreateCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mis Colecciones", style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showCreateDialog(context),
                tooltip: "Crear Colección",
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: collections.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    const Text("No tienes colecciones. ¡Crea una nueva!"),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: collections.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                    title: Text(collection.name),
                    subtitle: Text("${collection.recordings.length} elementos"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onCollectionSelected(collection),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Colección"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Ej. Entrevistas, Ideas, Clases...",
            labelText: "Nombre",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onCreateCollection(controller.text.trim());
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
