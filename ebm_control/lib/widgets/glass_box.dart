import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.05,
    this.borderRadius = AdminTheme.cardRadius,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(opacity) 
                : Colors.black.withOpacity(opacity * 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
