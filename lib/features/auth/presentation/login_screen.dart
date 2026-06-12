import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/config/app_config.dart';
import 'join_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_emailController.text, _passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or Icon
                    const Icon(Icons.security, size: 64, color: AppColors.primary),
                    const SizedBox(height: 24),
                    
                    Text(
                      'EBM Gateway',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manager & Staff Authentication',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('LOG IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // --- EBM ID SSO SECTION (Google Style) ---
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR", style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    OutlinedButton(
                      onPressed: () async {
                        // Optimized SSO Flow: App to App or Web to Web
                        final rawTarget = kIsWeb ? html.window.location.href.split('#').first : 'ebm-app://auth';
                        final encodedTarget = base64Url.encode(utf8.encode(rawTarget));
                        
                        final centralBase = AppConfig.centralUrl;
                        final centralWebSso = "$centralBase/#/authorize?target=$encodedTarget";
                        final centralAppSso = "ebm-central://authorize?target=$encodedTarget";

                        if (!kIsWeb) {
                          // Try to launch the installed app first
                          final appUri = Uri.parse(centralAppSso);
                          if (await canLaunchUrl(appUri)) {
                            await launchUrl(appUri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        }
                        
                        // Fallback to Browser SSO
                        final webUri = Uri.parse(centralWebSso);
                        await launchUrl(webUri, mode: LaunchMode.externalApplication);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.flash_on, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with EBM ID',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Received an invitation?', style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => JoinScreen()),
                            );
                          },
                          child: const Text('Join Team', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              key: const ValueKey('dev_auto_login_btn'),
              mini: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              child: const Icon(Icons.developer_mode_rounded),
              onPressed: () => _showDevAutoLoginSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showDevAutoLoginSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.developer_mode_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Developer Auto-Login (EBM)',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDevRoleButton(
                context: context,
                isDark: isDark,
                roleName: 'Manager',
                email: 'manager@ebfic.dev',
                password: 'password',
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 12),
              _buildDevRoleButton(
                context: context,
                isDark: isDark,
                roleName: 'Staff',
                email: 'staff@ebfic.dev',
                password: 'password',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildDevRoleButton(
                context: context,
                isDark: isDark,
                roleName: 'Custom Role',
                email: 'custom@ebfic.dev',
                password: 'password',
                icon: Icons.shield_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: This overlay is only visible during development (kDebugMode).',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDevRoleButton({
    required BuildContext context,
    required bool isDark,
    required String roleName,
    required String email,
    required String password,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _emailController.text = email;
              _passwordController.text = password;
            });
            _handleLogin();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            key: ValueKey('dev_login_$roleName'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
