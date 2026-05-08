import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../providers/chat_provider.dart';

class ChatProfileEditScreen extends StatefulWidget {
  const ChatProfileEditScreen({super.key});

  @override
  State<ChatProfileEditScreen> createState() => _ChatProfileEditScreenState();
}

class _ChatProfileEditScreenState extends State<ChatProfileEditScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late TextEditingController _aboutController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nicknameController = TextEditingController(text: auth.chatNickname);
    _bioController      = TextEditingController(text: auth.chatBio);
    _aboutController    = TextEditingController(text: auth.chatAbout);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname cannot be empty')),
      );
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final chatService = context.read<ChatProvider>().service;
      await chatService.updateProfile(
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        about: _aboutController.text.trim(),
      );

      if (mounted) {
        context.read<AuthProvider>().updateChatInfo(
          nickname: _nicknameController.text.trim(),
          bio: _bioController.text.trim(),
          about: _aboutController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated!',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to update. Try again.'; _isLoading = false; });
    }
  }

  void _copyChatNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Chat Number copied!',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final textColor  = isDark ? AppColors.textLight : AppColors.textDark;
    final width      = MediaQuery.of(context).size.width;
    final isWide     = width > 700;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Chat Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textColor, fontSize: 18)),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
              : TextButton(
                  onPressed: _handleSave,
                  child: Text('SAVE',
                      style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w900))),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 600.0 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(isDark),
                const SizedBox(height: 32),
                _buildTextField(label: 'NICKNAME', controller: _nicknameController,
                    hint: 'Your display name...', isDark: isDark),
                const SizedBox(height: 20),
                _buildTextField(label: 'BIO', controller: _bioController,
                    hint: 'A short sentence about you...', maxLength: 160, isDark: isDark),
                const SizedBox(height: 20),
                _buildTextField(label: 'ABOUT', controller: _aboutController,
                    hint: 'Detailed information...', maxLines: 4, isDark: isDark),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_error!,
                        style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13)),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile Header — shows avatar + 12-digit number
  // ─────────────────────────────────────────────
  Widget _buildProfileHeader(bool isDark) {
    final auth       = context.watch<AuthProvider>();
    final name       = auth.userName ?? 'User';
    final chatNumber = auth.chatNumber ?? '';
    final profileId  = auth.chatProfileId ?? '';
    final role       = (auth.userRole ?? 'STAFF').toUpperCase();

    // Role color
    Color roleColor = role == 'ADMIN'
        ? const Color(0xFF60A5FA)
        : role == 'MANAGER'
            ? const Color(0xFFFB923C)
            : const Color(0xFF34D399);

    return Center(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [roleColor, roleColor.withOpacity(0.6)]),
              boxShadow: [BoxShadow(color: roleColor.withOpacity(0.35), blurRadius: 20)],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name + role
          Text(name,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Text(role,
                style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.w900,
                    color: roleColor, letterSpacing: 1)),
          ),
          const SizedBox(height: 20),

          // ── 12-Digit Virtual Chat Number (tap to copy) ──
          if (chatNumber.isNotEmpty)
            GestureDetector(
              onTap: () => _copyChatNumber(chatNumber),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chatNumber,
                          style: GoogleFonts.outfit(
                              fontSize: 26, fontWeight: FontWeight.w900,
                              color: AppColors.primary, letterSpacing: 3),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.copy_rounded, size: 18, color: AppColors.primary.withOpacity(0.6)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '12-DIGIT VIRTUAL CHAT NUMBER  •  TAP TO COPY',
                      style: GoogleFonts.outfit(
                          fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                          color: isDark ? Colors.white30 : Colors.black38),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Text(
                'Complete profile setup to get your 12-digit number.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.orange, fontSize: 12),
              ),
            ),

          if (profileId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('@$profileId',
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white30 : Colors.black38,
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    int maxLines = 1,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white24 : Colors.black38,
                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white10 : Colors.black12),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
