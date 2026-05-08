import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class ControlCore extends StatefulWidget {
  final double size;
  const ControlCore({super.key, this.size = 40});

  @override
  State<ControlCore> createState() => _ControlCoreState();
}

class _ControlCoreState extends State<ControlCore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = AdminTheme.accent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CorePainter(
            progress: _controller.value,
            color: accentColor,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _CorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _CorePainter({required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.3 * (1 - progress) : 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * (0.8 + 0.2 * progress), glowPaint);

    // 2. Main Shield Shape
    final shieldPath = Path();
    for (int i = 0; i < 6; i++) {
        double angle = i * math.pi / 3 - math.pi / 2;
        double x = center.dx + radius * 0.7 * math.cos(angle);
        double y = center.dy + radius * 0.7 * math.sin(angle);
        if (i == 0) shieldPath.moveTo(x, y); else shieldPath.lineTo(x, y);
    }
    shieldPath.close();

    final mainPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawPath(shieldPath, mainPaint);

    // 3. Inner Detail (Rotating)
    final innerPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: radius * 0.3, height: radius * 0.3), innerPaint);
    canvas.restore();

    // 4. Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center.translate(-radius*0.2, -radius*0.2), radius * 0.1, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _CorePainter oldDelegate) => true;
}
