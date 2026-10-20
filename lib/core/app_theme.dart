import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette Originale v1 (Mode Clair)
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF6200EE);
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFF5252);

  // Palette Mode Sombre (conserve l'identité visuelle BDA)
  static const Color darkBackground = Color(0xFF12131A);
  static const Color darkSurface = Color(0xFF1E202B);
  static const Color darkSurfaceVariant = Color(0xFF282B3A);

  // Palette Mode Admin (Orange)
  static const Color adminPrimary = Color(0xFFFF6D00);
  static const Color adminSecondary = Color(0xFFFFAB40);

  static ThemeData getTheme({bool isAdmin = false, bool isDark = false}) {
    final mainColor = isAdmin ? adminPrimary : primary;
    final accentColor = isAdmin ? adminSecondary : secondary;
    final bgColor = isDark ? darkBackground : background;
    final surfaceColor = isDark ? darkSurface : surface;
    final surfaceVarColor = isDark ? darkSurfaceVariant : Colors.grey.shade100;
    final textPrimary = isDark ? const Color(0xFFF3F4F8) : Colors.black;
    final textSecondary = isDark ? const Color(0xFFD1D5DB) : Colors.black87;
    final textMuted = isDark ? const Color(0xFF9CA3AF) : Colors.black54;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: mainColor,
      cardColor: surfaceColor,
      dividerColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mainColor,
        primary: mainColor,
        secondary: accentColor,
        surface: surfaceColor,
        surfaceContainerHighest: surfaceVarColor,
        error: error,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: bgColor,

      // Typographie Moderne avec Contraste Renforcé
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textSecondary),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textSecondary),
        bodyLarge: GoogleFonts.poppins(color: textSecondary, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.poppins(color: textMuted, fontWeight: FontWeight.w400),
      ),

      // Composants Stylisés
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textSecondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: textSecondary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: mainColor.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: mainColor);
          }
          return IconThemeData(color: textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: mainColor,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          foregroundColor: Colors.white,
          elevation: isDark ? 4 : 8,
          shadowColor: mainColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceVariant : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: mainColor.withValues(alpha: 0.6), width: 2),
        ),
        prefixIconColor: mainColor,
        labelStyle: GoogleFonts.poppins(color: textMuted),
        hintStyle: GoogleFonts.poppins(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => Theme.of(this).cardColor;
  Color get surfaceVariantColor =>
      isDark ? AppTheme.darkSurfaceVariant : Colors.grey.shade100;
  Color get subtleSurfaceColor =>
      isDark ? const Color(0xFF181A24) : Colors.grey.shade50;
  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;
  Color get strongBorderColor =>
      isDark ? Colors.white.withValues(alpha: 0.16) : Colors.grey.shade300;
  Color get textPrimary =>
      isDark ? const Color(0xFFF3F4F8) : Colors.black;
  Color get textSecondary =>
      isDark ? const Color(0xFFD1D5DB) : Colors.black87;
  Color get textMuted =>
      isDark ? const Color(0xFF9CA3AF) : Colors.black54;
}
