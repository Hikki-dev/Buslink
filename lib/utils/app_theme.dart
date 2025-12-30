// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

// This class will manage and notify the app of theme changes
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Check device setting
  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

class AppTheme {
  // Brand Colors - Crimson Red Theme
  static const Color primaryColor = Color(0xFFBA181B);
  static const Color primaryDark = Color(0xFF660708);
  static const Color primaryLight = Color(0xFFE5383B);
  static const Color accentColor = Color(0xFFE5383B);

  static const Color darkText = Colors.black; // Pure Black for High Contrast
  static const Color lightText = Colors.black; // Pure Black
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F3F4);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Outfit',
    fontFamilyFallback: const ['Montserrat', 'Inter', 'NotoSans', 'sans-serif'],
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black, size: 28), // Bolder Icons
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        color: Colors.black,
        fontSize: 22, // Larger
        fontWeight: FontWeight.w800, // Extra Bold
      ),
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black,
      outline: Colors.black12, // Darker outline
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Cormorant',
        fontSize: 56, // Larger
        fontWeight: FontWeight.w900, // Black
        color: Colors.black,
        height: 1.1,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 40, // Larger
        fontWeight: FontWeight.w800, // Extra Bold
        color: Colors.black, // Pure Black
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 30, // Larger
        fontWeight: FontWeight.w800, // Extra Bold
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 20, // Larger base size for elderly
          color: Colors.black,
          fontWeight: FontWeight.w700), // Bold
      bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18, // Larger
          color: Colors.black,
          fontWeight: FontWeight.w600), // Semi-Bold
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800, // Extra Bold
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        elevation: 2,
        textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side:
            const BorderSide(color: primaryColor, width: 2.5), // Thicker border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.black54, // Darker hint
          fontWeight: FontWeight.w600),
      labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounder cards
        side: BorderSide(
            color: Colors.grey.shade300, width: 1.5), // Visible border
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D), // Almost Black
    fontFamily: 'Outfit',
    fontFamilyFallback: const ['Montserrat', 'Inter', 'NotoSans', 'sans-serif'],
    useMaterial3: true,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D0D0D),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white, size: 28),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1A1A), // Dark Grey Surface
      onSurface: Colors.white,
      primary: primaryColor,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Cormorant',
        fontSize: 56,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262626), // Lighter than background
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.5),
      ),
      hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.white60, // Clearer hint
          fontWeight: FontWeight.w600),
      labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w800),
    ),
  );
}
