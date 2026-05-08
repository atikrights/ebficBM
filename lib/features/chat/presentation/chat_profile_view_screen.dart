import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';

class ChatProfileViewScreen extends StatefulWidget {
  final int? userId;
  final String? receiverType;

  const ChatProfileViewScreen({super.key, this.userId, this.receiverType});

  @override
  State<ChatProfileViewScreen> createState() => _ChatProfileViewScreenState();
}

class _ChatProfileViewScreenState extends State<ChatProfileViewScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();
    final isMe = widget.userId == null || widget.userId == authState.userId;
    final isAi = widget.receiverType == 'ai';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    // Profile Data
    final String displayName = isAi ? 'AI Assistant' : (isMe ? (authState.chatNickname ?? authState.userName ?? 'User') : 'User');
    final String chatNumber  = isMe ? (authState.chatNumber ?? '') : '';
    final String displayBio = isAi ? 'EBM Central HD AI Engine' : (isMe ? (authState.chatBio ?? 'No bio yet...') : '');
    final String displayAbout = isAi ? 'I am a highly advanced artificial intelligence designed to assist with management, coding, and creative tasks within the EBM ecosystem.' : (isMe ? (authState.chatAbout ?? 'No additional information.') : '');

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(displayName, chatNumber, isAi),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(
                    label: 'NICKNAME',
                    value: displayName,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    label: 'BIO',
                    value: displayBio,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    label: 'ABOUT',
                    value: displayAbout,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  if (!isAi) _buildVirtualIdentityCard(chatNumber, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String name, String number, bool isAi) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.darkBackground, AppColors.darkSurface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isAi 
                    ? const LinearGradient(colors: [Colors.amberAccent, Colors.orangeAccent])
                    : const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [BoxShadow(color: (isAi ? Colors.amberAccent : AppColors.primary).withOpacity(0.3), blurRadius: 30)],
                ),
                child: Center(
                  child: isAi 
                    ? const Icon(Icons.auto_awesome, size: 50, color: Colors.white)
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              if (number.isNotEmpty)
                Text(
                  number,
                  style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection({required String label, required String value, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white24 : Colors.black38,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ],
    );
  }

  Widget _buildVirtualIdentityCard(String number, bool isDark) {
    if (number.isEmpty) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identity Copied: $number', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            width: 250,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.cyanAccent.withOpacity(0.05) : Colors.cyanAccent.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '12-DIGIT VIRTUAL NUMBER',
                    style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  Text(
                    number,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
