import 'package:flutter/material.dart';

class MobileNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MobileNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F111A).withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           _NavItem(
             icon: Icons.home_rounded, 
             label: "Inicio", 
             isSelected: currentIndex == 0, 
             onTap: () => onTap(0)
           ),
           _NavItem(
             icon: Icons.star_border_rounded, 
             activeIcon: Icons.star_rounded,
             label: "Favoritos", 
             isSelected: currentIndex == 1, 
             onTap: () => onTap(1)
           ),
           
           // Center Mic Button
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 8.0),
             child: Transform.translate(
               offset: const Offset(0, -25),
               child: Container(
                 width: 64,
                 height: 64,
                 decoration: BoxDecoration(
                   color: Theme.of(context).primaryColor,
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(
                       color: Theme.of(context).primaryColor.withOpacity(0.4),
                       blurRadius: 15,
                       offset: const Offset(0, 8),
                     )
                   ],
                   border: Border.all(
                     color: isDark ? const Color(0xFF0F111A) : Colors.white,
                     width: 6,
                   )
                 ),
                 child: Material(
                   color: Colors.transparent,
                   child: InkWell(
                     onTap: () => onTap(2), // 2 is typically the center action, but list might be structured differently
                     customBorder: const CircleBorder(),
                     child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
                   ),
                 ),
               ),
             ),
           ),

           _NavItem(
             icon: Icons.folder_open_rounded, 
             activeIcon: Icons.folder_rounded,
             label: "Colecciones", 
             isSelected: currentIndex == 3, 
             onTap: () => onTap(3)
           ),
           _NavItem(
             icon: Icons.settings_outlined, 
             activeIcon: Icons.settings_rounded,
             label: "Ajustes", 
             isSelected: currentIndex == 4, 
             onTap: () => onTap(4)
           ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
      ? Theme.of(context).primaryColor 
      : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? (activeIcon ?? icon) : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: color, 
                fontSize: 10, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }
}
