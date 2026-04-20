import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ClipboardHelper {
  /// Globally copies text to the clipboard and shows a beautiful, non-intrusive centered success notification.
  static Future<void> copy(
    BuildContext context, 
    String text, 
    {String notifyText = 'Copied'}
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconsaxPlusLinear.tick_circle, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              notifyText,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFF1A1A1A),
        duration: const Duration(milliseconds: 800),
        width: 130, // Forces the snackbar to be a small box centered at the bottom on all screen sizes
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        elevation: 10,
      ),
    );
  }
}
