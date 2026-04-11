import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    // সিম্পল সিকিউরিটি চেক (ভবিষ্যতে আমরা এটি Firebase Auth দিয়ে রিপ্লেস করব)
    // নোট: আসল প্রোডাকশনে আমরা এই পাসকোড হার্ডকোড করব না।
    await Future.delayed(const Duration(seconds: 1));
    
    if (_passController.text == "ebfic_admin_786") { 
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unauthorized Access Blocked!")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminTheme.accent.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, color: AdminTheme.accent, size: 48),
              const SizedBox(height: 24),
              const Text("EBM CONTROL CENTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 12),
              const Text("High-Level Security Authorization", style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 32),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter Super Admin Passcode",
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("AUTHORIZE ACCESS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
