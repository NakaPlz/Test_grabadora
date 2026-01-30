import 'package:flutter/material.dart';
import '../presentation/widgets/custom_toast.dart';

class ToastService {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, ToastType.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, ToastType.info);
  }

  static void _show(BuildContext context, String message, ToastType type) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar(); // Remove previous if stacking
    scaffold.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        content: CustomToast(message: message, type: type),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
