import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class BroadcastScreen extends StatelessWidget {
  const BroadcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : theme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconsaxPlusLinear.radar,
                size: 64,
                color: isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Broadcast Analysis',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cross-site analysis will be available here soon.',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
