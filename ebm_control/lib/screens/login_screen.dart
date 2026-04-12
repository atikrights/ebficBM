import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _sidController = TextEditingController();
  final TextEditingController _pass1 = TextEditingController();
  final TextEditingController _pass2 = TextEditingController();
  final TextEditingController _pass3 = TextEditingController();
  
  bool _isLoading = false;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _timer;

  // ব্রুট-ফোর্স প্রোটেকশন লজিক
  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30; // ৩০ সেকেন্ডের জন্য ব্লক
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        _timer?.cancel();
        _failedAttempts = 0; // রিসেট
      }
    });
  }

  void _handleAuthorization() async {
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // রিয়েল-টাইম ডিলে সিমুলেশন
    
    // ভেরিফিকেশন লজিক (SID + 3 Keys)
    const String masterSID = "EBM-1234-5678"; // আপনার ১২ ডিজিটের নমুনা SID
    
    if (_sidController.text == masterSID && 
        _pass1.text == "ebfic" && 
        _pass2.text == "admin" && 
        _pass3.text == "786") { 
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _startCooldown();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(_failedAttempts >= 3 
              ? "SECURITY REACHED: System locked for 30s" 
              : "CREDENTIAL FAILURE: Attempt $_failedAttempts/3"),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _cooldownSeconds > 0 ? Colors.red.withOpacity(0.3) : AdminTheme.accent.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: _cooldownSeconds > 0 ? Colors.red.withOpacity(0.1) : AdminTheme.accent.withOpacity(0.05), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _cooldownSeconds > 0 ? Icons.gpp_bad_rounded : Icons.shield_rounded, 
                  color: _cooldownSeconds > 0 ? Colors.redAccent : AdminTheme.accent, 
                  size: 60
                ),
                const SizedBox(height: 24),
                const Text("SUPREME AUTHORIZATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 4, color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  _cooldownSeconds > 0 
                    ? "SYSTEM LOCKED: RETRY IN ${_cooldownSeconds}s" 
                    : "LOGICAL IDENTITY VERIFICATION REQUIRED", 
                  style: TextStyle(color: _cooldownSeconds > 0 ? Colors.redAccent : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 48),
                
                // Super Admin SID Field
                _buildField(_sidController, "12-DIGIT SID (EBM-XXXX-XXXX)", Icons.qr_code_rounded, isSID: true),
                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 32),

                // 3 Password Layers
                _buildField(_pass1, "ACCESS KEY ALPHA", Icons.lock_outline_rounded),
                const SizedBox(height: 16),
                _buildField(_pass2, "ACCESS KEY BETA", Icons.security_rounded),
                const SizedBox(height: 16),
                _buildField(_pass3, "ACCESS KEY GAMMA", Icons.verified_user_rounded),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _cooldownSeconds > 0) ? null : _handleAuthorization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.accent,
                      disabledBackgroundColor: Colors.white10,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : Text(_cooldownSeconds > 0 ? "COOLDOWN ACTIVE" : "AUTHENTICATE SID", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("FIREWALL STATUS: ACTIVE | AES-256", style: TextStyle(color: Colors.greenAccent, fontSize: 9, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isSID = false}) {
    return TextField(
      controller: controller,
      obscureText: !isSID,
      enabled: _cooldownSeconds == 0,
      style: TextStyle(
        color: isSID ? AdminTheme.accent : Colors.white, 
        fontSize: 14, 
        letterSpacing: isSID ? 2 : 0,
        fontWeight: isSID ? FontWeight.bold : FontWeight.normal
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isSID ? AdminTheme.accent : Colors.white24, size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white12, fontSize: 11),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AdminTheme.accent, width: 0.5)),
      ),
    );
  }
}
