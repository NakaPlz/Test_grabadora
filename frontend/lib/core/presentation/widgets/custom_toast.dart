import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onDismiss;

  const CustomToast({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    Color textColor = Colors.white;

    switch (type) {
      case ToastType.success:
        bg = const Color(0xFF10B981); // Emerald 500
        icon = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        bg = const Color(0xFFEF4444); // Red 500
        icon = Icons.error_outline_rounded;
        break;
      case ToastType.info:
      default:
        bg = const Color(0xFF3B82F6); // Blue 500
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close,
                    color: Colors.white.withOpacity(0.8), size: 16))
          ]
        ],
      ),
    );
  }
}
