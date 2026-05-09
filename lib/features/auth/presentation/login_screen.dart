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
      body: Center(
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
    );
  }
}
