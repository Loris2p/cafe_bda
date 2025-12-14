import 'package:flutter/material.dart';

/// Définition du Design System de l'application Café BDA.
class AppTheme {
  // --- 1. Palette de Couleurs (Color Palette) ---
  
  // Violet Principal (Primary) : Un violet profond et moderne
  // static const Color primary = Color(0xFF6200EE); 
  static const Color primary = Color(0xFFBB86FC); 
  // Violet Secondaire (Secondary) : Un ton plus clair pour les accents
  // static const Color secondary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF6200EE);
  // Violet Sombre (Variant) : Pour les éléments de contraste fort
  static const Color primaryVariant = Color(0xFF3700B3);
  
  // Neutres
  static const Color background = Color(0xFFF5F7FA); // Gris très pâle (légèrement bleuté) pour le fond
  static const Color surface = Colors.white;         // Cartes et dialogues
  static const Color error = Color(0xFFB00020);
  static const Color textPrimary = Color(0xFF1D1D1D); // Noir doux (jamais #000000 pur)
  static const Color textSecondary = Color(0xFF757575); // Gris moyen

  // --- 2. Espacement (Spacing Scale) ---
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // --- 3. Bordures (Border Radius) ---
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;

  /// Retourne le thème clair configuré (Light Theme).
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Configuration des couleurs globales
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      
      scaffoldBackgroundColor: background,
      
      // Configuration de la Typographie (Basée sur Material 3 mais ajustée)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary), // Corps de texte principal
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary), // Sous-titres, détails
      ),

      // Styles des Composants Réutilisables
      
      // 1. Cartes (Card)
      /* cardTheme removed due to type mismatch in current flutter version */

      // 2. Champs de saisie (Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // 3. Boutons (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      
      // 4. Boutons Texte (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      
      // 5. AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      
      // 6. Floating Action Button & Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
