import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors (Cashbit Style) ---
  static const Color primaryColor = Color(0xFFCCFF00); // Neon Lime (Cashbit Green)
  static const Color secondaryColor = Color(0xFF00E676); // Bright Green
  static const Color accentColor = Color(0xFF6366F1); // Indigo (Secondary accent)

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF4F4F5); 
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Color(0xFF71717A);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF09090B); // Almost Pure Black
  static const Color darkSurface = Color(0xFF18181B); // Zinc 900
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // cardTheme removed due to type mismatch

  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // cardTheme removed due to type mismatch

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF27272A), // Zinc 800
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
