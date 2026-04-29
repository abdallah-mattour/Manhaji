import 'package:flutter/material.dart';

class AppTheme {
  // Spacing scale
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;

  // Child-friendly colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryRed = Color(0xFFF44336);

  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGray = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);

  // Subject colors
  static const List<Color> subjectColors = [
    Color(0xFF2196F3), // Arabic - Blue
    Color(0xFF4CAF50), // Math - Green
    Color(0xFF9C27B0), // Islamic - Purple
    Color(0xFFFF9800), // Science - Orange
  ];

  static const List<Color> subjectLightColors = [
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFF3E5F5),
    Color(0xFFFFF3E0),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: primaryBlue,
        surface: cardWhite,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: textLight),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        headlineSmall: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: textGray),
        labelLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
