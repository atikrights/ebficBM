import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';

class ChatProfileSetupScreen extends StatefulWidget {
  const ChatProfileSetupScreen({super.key});

  @override
  State<ChatProfileSetupScreen> createState() => _ChatProfileSetupScreenState();
}

class _ChatProfileSetupScreenState extends State<ChatProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _fullChatId = "...";
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authState = context.read<AuthProvider>();
    if (authState.chatProfileId != null && authState.chatProfileId!.isNotEmpty) {
      setState(() {
        _fullChatId = authState.chatProfileId!;
        _nameController.text = authState.chatNickname ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSetup() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = "Please enter your name.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = context.read<ChatProvider>().service;
      final response = await chatService.setupProfileWithResponse(_nameController.text.trim());
      
      if (response['success'] == true) {
        if (mounted) {
          context.read<AuthProvider>().updateChatInfo(
            id: response['chat_profile_id'],
            number: response['chat_number'],
            nickname: _nameController.text.trim()
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response['error'] ?? "Failed to activate profile.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Connection error. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_fullChatId != "..." && _fullChatId != "Generating...") {
      Clipboard.setData(ClipboardData(text: _fullChatId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat Virtual Number copied!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.textLight : AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      ),
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(top: -120, right: -60, child: _GlowCircle(color: AppColors.primary.withOpacity(0.06))),
            Positioned(bottom: -120, left: -60, child: _GlowCircle(color: AppColors.secondary.withOpacity(0.06))),
          ] else ...[
            Positioned(top: -120, right: -60, child: _GlowCircle(color: AppColors.primary.withOpacity(0.03))),
            Positioned(bottom: -120, left: -60, child: _GlowCircle(color: AppColors.secondary.withOpacity(0.03))),
          ],

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 360 : 380),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.white.withOpacity(0.04) 
                          : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.5) : AppColors.primary.withOpacity(0.05), 
                            blurRadius: 40, 
                            offset: const Offset(0, 20)
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderIcon(isDark),
                          const SizedBox(height: 24),
                          _buildTitle(isDark),
                          const SizedBox(height: 12),
                          _buildDescription(isDark),
                          const SizedBox(height: 36),
                          _buildIdDisplay(isDark),
                          const SizedBox(height: 28),
                          _buildNameField(isDark),
                          if (_error != null) _buildErrorText(),
                          const SizedBox(height: 36),
                          _buildContinueButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
        shape: BoxShape.circle,
        boxShadow: [
          if (isDark) BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: const Icon(Icons.forum_rounded, size: 38, color: AppColors.primary),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      'Profile Setup',
      style: GoogleFonts.outfit(
        fontSize: 26, 
        fontWeight: FontWeight.w800, 
        color: isDark ? Colors.white : AppColors.textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDescription(bool isDark) {
    return Text(
      'Official EBM Chat System.\nSetup your profile here to proceed to the chat.',
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        color: isDark ? Colors.white38 : AppColors.textDark.withOpacity(0.6), 
        fontSize: 13, 
        height: 1.5,
      ),
    );
  }

  Widget _buildIdDisplay(bool isDark) {
    final authState = context.watch<AuthProvider>();
    String displayId = authState.chatNumber ?? _fullChatId;
    
    String baseId = "";
    String suffixId = "";
    if (displayId.length > 4 && displayId != 'ID_NOT_SET') {
      baseId = displayId.substring(0, displayId.length - 4);
      suffixId = displayId.substring(displayId.length - 4);
    } else {
      baseId = displayId;
    }

    return Tooltip(
      message: 'Click to copy',
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: displayId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Virtual Number copied!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : AppColors.primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 26, 
                        fontWeight: FontWeight.w900, 
                        color: isDark ? Colors.white : AppColors.textDark, 
                        letterSpacing: 2.5
                      ),
                      children: [
                        TextSpan(text: baseId),
                        TextSpan(
                          text: suffixId,
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(isDark ? 0.8 : 1.0),
                            shadows: [
                              if (isDark) BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.copy_all_rounded, size: 18, color: AppColors.primary.withOpacity(0.6)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '12-DIGIT VIRTUAL CHAT NUMBER',
                style: GoogleFonts.outfit(
                  color: AppColors.primary.withOpacity(0.8), 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR NICKNAME', 
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white24 : AppColors.textDark.withOpacity(0.4), 
            fontSize: 11, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.5
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          style: GoogleFonts.outfit(color: isDark ? Colors.white : AppColors.textDark, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
            hintText: 'e.g. Your Name...',
            hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white10 : Colors.black12, fontSize: 15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        _error!, 
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: AppColors.error, fontSize: 12, height: 1.4)
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25), 
            blurRadius: 25, 
            offset: const Offset(0, 10)
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), 
          elevation: 0
        ),
        onPressed: _isLoading ? null : _handleSetup,
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(
              'ACTIVATE CHAT PROFILE', 
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8)
            ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  const _GlowCircle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, 
      height: 320, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]
      ),
    );
  }
}
