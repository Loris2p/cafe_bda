import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette Originale v1
  static const Color primary = Color(0xFFBB86FC); 
  static const Color secondary = Color(0xFF6200EE);
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFF5252);
  
  static const Color adminPrimary = Color(0xFFFF6D00); // Orange pour le mode admin
  static const Color adminSecondary = Color(0xFFFFAB40);

  static ThemeData getTheme({bool isAdmin = false}) {
    final mainColor = isAdmin ? adminPrimary : primary;
    final accentColor = isAdmin ? adminSecondary : secondary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mainColor,
        primary: mainColor,
        secondary: accentColor,
        surface: surface,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      
      // Typographie Moderne avec Contraste Renforcé
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.w400),
      ),

      // Composants Stylisés
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black87,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: mainColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: mainColor.withValues(alpha: 0.5), width: 2),
        ),
        prefixIconColor: mainColor,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
    );
  }
}
