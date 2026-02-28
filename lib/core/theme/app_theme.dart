import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors (High-Precision Figma Tokens) ---
  static const Color primaryColor = Color(0xFFF9C06A); // Warm Amber
  static const Color secondaryColor = Color(0xFF482706); // Deep Coffee Brown
  static const Color accentColor = Color(0xFFA99C87); // Muted Taupe
  static const Color deepBrown = Color(0xFF76410B); // Icon & CTA text color
  static const Color cardBackground = Color(0xFFFFFDF7); // Premium Cream card bg
  static const Color sectionTitle = Color(0xFF434343); // Section headers
  static const Color bodyText = Color(0xFF4A4A4A); // Body/label text
  static const Color borderGrey = Color(0xFFDADADA); // Button borders
  static const Color activeDot = Color(0xFFEF9E24); // Active carousel dot
  static const Color inactiveDot = Color(0xFFA99B87); // Inactive carousel dot
  static const Color starFilled = Color(0xFFE68A00); // Filled review star
  static const Color starEmpty = Color(0xFF6D6D6D); // Empty review star
  static const Color qrGradientStart = Color(0xFFF4BD6B); // QR button gradient start
  static const Color qrGradientEnd = Color(0xFFFD9300); // QR button gradient end
  static const Color puanHarcaBg = Color(0xFFF9CF92); // Puan Harca background
  static const Color puanHarcaText = Color(0xFFF89D13); // Puan Harca text/icon
  static const Color campaignBtnBg = Color(0xFFF9C06A); // "Detayları Gör" bg
  static const Color campaignBtnText = Color(0xFF76410B); // "Detayları Gör" text
  static const Color kesifTileBg = Color(0xFFFFE5BE); // "Diğer Kampanyalar" bg

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFFFDF7); // Premium Cream
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF121212); // Onyx
  static const Color lightTextSecondary = Color(0xFF4A4A4A); // Charcoal

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212); // Bauhaus Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Deep Grey
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA99C87);

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
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      bodyLarge: const TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: const TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w400),
      titleLarge: const TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Outfit',
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
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      centerTitle: false,
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
