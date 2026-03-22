import 'package:flutter/material.dart';

enum SidebarSection { all, favorites, collections, trash, settings }

class AppSidebar extends StatelessWidget {
  final VoidCallback onNewRecording;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final VoidCallback onLogout;
  final SidebarSection currentSection;
  final ValueChanged<SidebarSection> onSectionChanged;

  const AppSidebar({
    super.key,
    required this.onNewRecording,
    required this.onSync,
    required this.onUpload,
    required this.onLogout,
    required this.currentSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Bridge AI",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NavParams(
                  icon: Icons.mic,
                  label: "Mis Grabaciones",
                  isSelected: currentSection == SidebarSection.all,
                  theme: theme,
                  onTap: () => onSectionChanged(SidebarSection.all),
                ),
                _NavParams(
                  icon: currentSection == SidebarSection.favorites ? Icons.star : Icons.star_border,
                  label: "Favoritos",
                  isSelected: currentSection == SidebarSection.favorites,
                  theme: theme,
                  onTap: () => onSectionChanged(SidebarSection.favorites),
                ),
                _NavParams(
                  icon: Icons.folder_open,
                  label: "Colecciones",
                  isSelected: currentSection == SidebarSection.collections,
                  theme: theme,
                  onTap: () => onSectionChanged(SidebarSection.collections),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Text(
                    "GESTIÓN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                 _NavParams(
                  icon: Icons.delete_outline,
                  label: "Papelera",
                  isSelected: currentSection == SidebarSection.trash,
                  theme: theme,
                  onTap: () => onSectionChanged(SidebarSection.trash),
                ),
                _NavParams(
                  icon: Icons.settings_outlined,
                  label: "Ajustes",
                  isSelected: currentSection == SidebarSection.settings,
                  theme: theme,
                  onTap: () => onSectionChanged(SidebarSection.settings),
                ),
                // Logout Item
                _NavParams(
                  icon: Icons.logout,
                  label: "Cerrar Sesión",
                  isSelected: false,
                  theme: theme,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: onSync,
                  icon: const Icon(Icons.sync),
                  label: const Text("Sincronizar"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Subir Audio"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onNewRecording,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Nueva Grabación"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavParams extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _NavParams({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
        ),
        title: Text(
          label,
          style: TextStyle(
             color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
             fontSize: 14,
          ),
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
