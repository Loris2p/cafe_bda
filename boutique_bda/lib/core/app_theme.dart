import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFBB86FC); 
  static const Color secondary = Color(0xFF6200EE);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData getTheme({bool isAdmin = false}) {
    final primaryColor = isAdmin ? Colors.deepOrange : primary;
    final secondaryColor = isAdmin ? Colors.orange : secondary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.black,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
