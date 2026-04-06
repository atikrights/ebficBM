import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - More vibrant and premium
  static const Color primary = Color(0xFF4F46E5); // Indigo deeply rich
  static const Color secondary = Color(0xFF9333EA); // Purple electric
  static const Color accent = Color(0xFFE11D48); // Rose red
  
  // Neutral Palette (Dark mode oriented) - True rich dark backgrounds
  static const Color darkBackground = Color(0xFF09090B); // Very dark zinc
  static const Color darkSurface = Color(0xFF18181B); // Dark zinc surface
  static const Color lightBackground = Color(0xFFF4F6F9); // Soft premium off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  
  static const Color glassBase = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x66FFFFFF),
      Color(0x1AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
