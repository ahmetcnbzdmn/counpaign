import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:counpaign/core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode = ThemeMode.light; // START with Light Default

  ThemeProvider(this._storageService) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    final isDark = await _storageService.getTheme();
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _storageService.saveTheme(isDark);
    notifyListeners();
  }

  // Define Themes
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0E13),
    cardColor: const Color(0xFF1E2329),
    primaryColor: const Color(0xFFEE2C2C), // New Brand Red
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFEE2C2C),
      secondary: Color(0xFFEE2C2C),
      surface: Color(0xFF1E2329),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F3F5), 
    cardColor: Colors.white,
    primaryColor: const Color(0xFFEE2C2C), // New Brand Red
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFEE2C2C),
      secondary: Color(0xFFEE2C2C),
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
