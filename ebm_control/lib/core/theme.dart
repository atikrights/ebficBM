import 'package:flutter/material.dart';

class AdminTheme {
  // Global Theme Controller
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  // Dark Mode Palette
  static const Color background = Color(0xFF0A0B10);
  static const Color surface = Color(0xFF16181F);
  static const Color accent = Color(0xFF00D1FF);
  
  // Light Mode Palette
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Colors.white;
  static const Color accentLight = Color(0xFF007AFF);

  // Glassmorphism Constants
  static Color glassColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withOpacity(0.05) 
      : Colors.black.withOpacity(0.03);
      
  static Color glassBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withOpacity(0.1) 
      : Colors.black.withOpacity(0.05);

  static const double cardRadius = 24.0;

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    fontFamily: 'Outfit',
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      onSurface: Colors.white,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    useMaterial3: true,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.light(
      primary: accentLight,
      surface: surfaceLight,
      onSurface: Colors.black,
    ),
  );
}
