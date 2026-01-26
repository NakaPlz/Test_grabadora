import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // TODO: REEMPLAZA ESTO CON LA URL DE TU DOMINIO EN EASYPANEL
  // Ejemplo: https://api.tu-dominio.com
  // No pongas la barra final (/)
  static const String _productionUrl = 'https://omni-crm-test-grabadora.l55xrw.easypanel.host/';

  // URLs locales para desarrollo
  static const String _windowsLocalUrl = 'http://127.0.0.1:8001';
  static const String _androidLocalUrl = 'http://10.0.2.2:8001';

  static String get baseUrl {
    // Si construimos en modo Release (flutter build apk --release), usamos PROD
    if (kReleaseMode) {
      return _productionUrl;
    }

    // Si estamos probando en el emulador de Android
    if (Platform.isAndroid) {
      return _androidLocalUrl;
    }

    // Por defecto (Windows debug, iOS simulator)
    return _windowsLocalUrl;
  }
}
