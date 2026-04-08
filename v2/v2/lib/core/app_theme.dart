import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE2C98D),
        brightness: Brightness.dark,
        primary: const Color(0xFFE2C98D),
        secondary: const Color(0xFF94A3B8),
        surface: const Color(0xFF202020), // Notion Dark Surface
        background: const Color(0xFF191919), // Notion Dark Background
      ),
      scaffoldBackgroundColor: const Color(0xFF191919),
      textTheme: GoogleFonts.getTextTheme('Geist', ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        bodyLarge: const TextStyle(
          height: 1.6,
          fontSize: 16,
          color: Color(0xFFEFEFEF),
        ),
        bodyMedium: const TextStyle(
          height: 1.6,
          fontSize: 14,
          color: Color(0xFFACACAC),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF202020),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Subtle rounding like Notion
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.05),
        thickness: 1.0,
      ),
    );
  }

  static BoxDecoration glassDecoration({double opacity = 0.1, double blur = 10}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    );
  }
}
