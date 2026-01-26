import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/settings_service.dart';

class SettingsPanel extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsPanel({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsService,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              "Configuración",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader(context, "Apariencia"),
            const SizedBox(height: 16),
            _buildThemeSelector(context),
            
            const SizedBox(height: 32),
            _buildSectionHeader(context, "Sincronización"),
            const SizedBox(height: 16),
            _buildPathInput(context),
            
            const SizedBox(height: 32),
            _buildSectionHeader(context, "Acerca de"),
            const SizedBox(height: 16),
            const ListTile(
              title: Text("Versión"),
              subtitle: Text("1.0.0 (MVP)"),
              leading: Icon(Icons.info_outline),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text("Sistema"),
            value: ThemeMode.system,
            groupValue: settingsService.themeMode,
            onChanged: (val) => settingsService.updateThemeMode(val!),
          ),
          const Divider(height: 1),
          RadioListTile<ThemeMode>(
            title: const Text("Claro"),
            value: ThemeMode.light,
            groupValue: settingsService.themeMode,
            onChanged: (val) => settingsService.updateThemeMode(val!),
          ),
          const Divider(height: 1),
          RadioListTile<ThemeMode>(
            title: const Text("Oscuro"),
            value: ThemeMode.dark,
            groupValue: settingsService.themeMode,
            onChanged: (val) => settingsService.updateThemeMode(val!),
          ),
        ],
      ),
    );
  }

  Widget _buildPathInput(BuildContext context) {
    final controller = TextEditingController(text: settingsService.watchPath);
    
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Carpeta de Grabaciones"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller, // Read-only mostly if picking
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: "Selecciona una carpeta...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                          settingsService.updateWatchPath(selectedDirectory);
                      }
                  },
                  icon: const Icon(Icons.folder_open),
                  tooltip: "Seleccionar carpeta",
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Esta es la carpeta que la app 'vigilará' en busca de nuevos archivos de audio.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
