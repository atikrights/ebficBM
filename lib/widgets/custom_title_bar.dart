import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ebficbm/core/theme/colors.dart';


class CustomTitleBar extends StatelessWidget {
  final bool isDark;
  const CustomTitleBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Hide the entire title bar or just parts of it on Web if desired.
    // Usually, we want the title but not the window buttons.
    
    return Container(
      height: 33,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background Drag Layer (Entire Bar) - Only for Desktop
          if (!kIsWeb)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  if (!kIsWeb) windowManager.startDragging();
                },
                onDoubleTap: () async {
                  if (!kIsWeb) {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  }
                },
              ),
            ),
          
          // Content Layer (Title & Buttons)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    "ebfic Business Manager",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Mac-style Window Controls on the Right - Only for Desktop
              if (!kIsWeb)
                GestureDetector(
                  onPanStart: (_) {}, 
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _MacDotButton(
                          color: const Color(0xFFFF5F57),
                          icon: Icons.close_rounded,
                          onTap: () {
                            if (!kIsWeb) windowManager.close();
                          },
                        ),
                        const SizedBox(width: 10),
                        _MacDotButton(
                          color: const Color(0xFFFFBD2E),
                          icon: Icons.remove_rounded,
                          onTap: () {
                            if (!kIsWeb) windowManager.minimize();
                          },
                        ),
                        const SizedBox(width: 10),
                        _MacDotButton(
                          color: const Color(0xFF28C840),
                          icon: Icons.add_rounded,
                          onTap: () async {
                            if (!kIsWeb) {
                              if (await windowManager.isMaximized()) {
                                windowManager.unmaximize();
                              } else {
                                windowManager.maximize();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _MacDotButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MacDotButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MacDotButton> createState() => _MacDotButtonState();
}

class _MacDotButtonState extends State<_MacDotButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_isHovering ? 1.0 : 0.9),
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
            boxShadow: _isHovering ? [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 0.5,
              )
            ] : null,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isHovering ? 1.0 : 0.0,
            child: Center(
              child: Icon(
                widget.icon,
                size: 8.5,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



