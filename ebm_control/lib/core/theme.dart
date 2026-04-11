import 'package:flutter/material.dart';

class AdminTheme {
  static const Color background = Color(0xFF0A0B10);
  static const Color surface = Color(0xFF16181F);
  static const Color accent = Color(0xFF00D1FF);
  static const Color textMain = Colors.white;
  static const Color textDim = Colors.white70;

  static const double compactPadding = 12.0;
  static const double cardRadius = 16.0;

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      onSurface: textMain,
    ),
  );
}
