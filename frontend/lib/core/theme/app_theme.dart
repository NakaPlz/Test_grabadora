import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightPrimary = Color(0xFF7C3AED); // Hilo Purple
  static const Color lightBackground = Color(0xFFF8F9FC); // Hilo Light BG
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Mode Colors
  static const Color darkPrimary = Color(0xFF7C3AED); // Hilo Purple
  static const Color darkBackground = Color(0xFF0F111A); // Hilo Dark BG
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800 (Lighter than BG)
  static const Color darkSidebar = Color(0xFF1A1F35); // Hilo Sidebar Dark
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: Colors.white,
        secondary: lightPrimary, // Using primary as secondary for now
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        surfaceContainer: lightBackground, // Material 3 background
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: lightTextSecondary,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkPrimary,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainer: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: darkTextSecondary,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
