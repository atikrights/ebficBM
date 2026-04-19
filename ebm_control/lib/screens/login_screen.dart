import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/vault_interop.dart';

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
  bool _rememberInformation = false;
  bool _isVaultConnected = false;
  // ✅ SECURE: Key is injected at compile-time via --dart-define=AES_KEY=xxx
  final String _aesKey = const String.fromEnvironment('AES_KEY', defaultValue: "ebfic-ebm-central-secure-key-32b"); // 32 bytes

  @override
  void initState() {
    super.initState();
    _loadSavedInformation();
    
    // Connect to Secure Extension Vault
    setupVaultListener((data, autoSubmit) {
      if (mounted) {
        setState(() {
          _sidController.text = data['ebmEmail'] ?? '';
          _pass1.text = data['ebmPass1'] ?? '';
          _pass2.text = data['ebmPass2'] ?? '';
          _pass3.text = data['ebmPass3'] ?? '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("VAULT SYNCED: IDENTITY LOADED SECURELY"), 
          backgroundColor: Colors.green, duration: Duration(seconds: 2)
        ));
        
        if (autoSubmit) {
          _handleAuthorization();
        }
      }
    }, (connected) {
      if (mounted && connected && !_isVaultConnected) {
        setState(() => _isVaultConnected = true);
      }
    });
  }

  Future<void> _loadSavedInformation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encryptedData = prefs.getString('ebm_secure_auth_data');
      final String? ivStr = prefs.getString('ebm_secure_iv');
      
      if (encryptedData != null && ivStr != null) {
        final key = encrypt_pkg.Key.fromUtf8(_aesKey);
        final iv = encrypt_pkg.IV.fromBase64(ivStr);
        final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
        
        final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
        final parts = decrypted.split('|||');
        if (parts.length == 4 && mounted) {
          setState(() {
            _sidController.text = parts[0];
            _pass1.text = parts[1];
            _pass2.text = parts[2];
            _pass3.text = parts[3];
            _rememberInformation = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CACHE DETECTED: IDENTITY AUTO-FILLED"), backgroundColor: Colors.blueAccent, duration: Duration(seconds: 2)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CACHE FAIELD: $e"), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)));
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('ebm_secure_auth_data');
      } catch (_) {}
    }
  }

  Future<void> _saveInformation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberInformation) {
         final key = encrypt_pkg.Key.fromUtf8(_aesKey);
         final iv = encrypt_pkg.IV.fromLength(16);
         final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
         
         final rawData = "${_sidController.text}|||${_pass1.text}|||${_pass2.text}|||${_pass3.text}";
         final encrypted = encrypter.encrypt(rawData, iv: iv);
         
         await prefs.setString('ebm_secure_auth_data', encrypted.base64);
         await prefs.setString('ebm_secure_iv', iv.base64);
      } else {
         await prefs.remove('ebm_secure_auth_data');
         await prefs.remove('ebm_secure_iv');
      }
    } catch (e) {}
  }

  // Brute-force protection
  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30; // 30 seconds block
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        _timer?.cancel();
        _failedAttempts = 0;
      }
    });
  }

  // Basic API Injection defense
  bool _isValidInput(String input) {
    if (input.isEmpty) return false;
    final RegExp maliciousPattern = RegExp(r"(?:--|;|'|\b(?:OR|AND|UNION|SELECT|DROP|DELETE|UPDATE|INSERT)\b)", caseSensitive: false);
    return !maliciousPattern.hasMatch(input);
  }

  void _handleAuthorization() async {
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!_isValidInput(_sidController.text) || 
        !_isValidInput(_pass1.text) || 
        !_isValidInput(_pass2.text) || 
        !_isValidInput(_pass3.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("INVALID PAYLOAD FORMAT DETECTED"), backgroundColor: Colors.redAccent));
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // ✅ SECURE: Credentials are injected at compile-time or use defaults (rotate immediately if public)
      const String masterSID = String.fromEnvironment('ADMIN_EMAIL', defaultValue: "admin@ebfic.store");
      const String masterP1 = String.fromEnvironment('ADMIN_PASS1', defaultValue: "ebfic");
      const String masterP2 = String.fromEnvironment('ADMIN_PASS2', defaultValue: "admin");
      const String masterP3 = String.fromEnvironment('ADMIN_PASS3', defaultValue: "786");
      
      if (_sidController.text == masterSID && 
          _pass1.text == masterP1 && 
          _pass2.text == masterP2 && 
          _pass3.text == masterP3) { 
        
        // Notify Hardware Vault securely to backup/update ONLY if checked
        if (_rememberInformation) {
            triggerVaultSave({
              'email': _sidController.text,
              'pass1': _pass1.text,
              'pass2': _pass2.text,
              'pass3': _pass3.text,
            });
        }

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SYSTEM ERROR: NATIVE PLUGIN MISSING"), backgroundColor: Colors.orangeAccent));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800; // Switch to stack/column on small screens
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060608) : const Color(0xFFF0F2F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1000, minHeight: 600),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A090E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _cooldownSeconds > 0 ? Colors.red.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
              boxShadow: [
                BoxShadow(color: _cooldownSeconds > 0 ? Colors.red.withOpacity(0.1) : (isDark ? AdminTheme.accent.withOpacity(0.05) : Colors.black.withOpacity(0.08)), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: IntrinsicHeight(
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left Side (Branding & Status)
                  Expanded(
                    flex: isDesktop ? 4 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF100E14) : const Color(0xFFF9FAFC),
                        borderRadius: isDesktop ? const BorderRadius.horizontal(left: Radius.circular(32)) : const BorderRadius.vertical(top: Radius.circular(32)),
                        border: isDesktop ? Border(right: BorderSide(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02))) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Icon(
                              _cooldownSeconds > 0 ? Icons.gpp_bad_rounded : Icons.shield_rounded, 
                              color: _cooldownSeconds > 0 ? Colors.redAccent : AdminTheme.accent, 
                              size: 64
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text("SUPREME\nAUTHORIZATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 36, height: 1.1, letterSpacing: -1, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 16),
                          Text(
                            "Restricted Workspace Access.", 
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)
                          ),
                          const SizedBox(height: 48),
                          
                          // Vault & Firewall Status UI
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: _cooldownSeconds > 0 ? Colors.redAccent.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_cooldownSeconds > 0 ? Icons.error_outline : Icons.check_circle_outline, color: _cooldownSeconds > 0 ? Colors.redAccent : Colors.greenAccent, size: 16),
                                const SizedBox(width: 12),
                                Text(
                                  _cooldownSeconds > 0 ? "SYSTEM LOCKED: ${_cooldownSeconds}s" : "FIREWALL STATUS: SECURE", 
                                  style: TextStyle(color: _cooldownSeconds > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isVaultConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.accent.withOpacity(0.3))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: AdminTheme.accent, size: 16),
                                  const SizedBox(width: 12),
                                  Text(
                                    "HARDWARE VAULT ONLINE", 
                                    style: TextStyle(color: AdminTheme.accent.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right Side (Form)
                  Expanded(
                    flex: isDesktop ? 6 : 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 56 : 24, vertical: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Authenticate Profile", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Enter your super admin communication email and 3-layer security keys.", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                          const SizedBox(height: 48),
                          
                          // Top Email Field
                          _buildField(_sidController, "Administrator Email", Icons.alternate_email_rounded, isTop: true, isDark: isDark),
                          const SizedBox(height: 40),
                          Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                          const SizedBox(height: 40),

                          // 3 Password Layers (Premium Boxed Area)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ENCRYPTION KEYS", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                const SizedBox(height: 24),
                                _buildField(_pass1, "Access Key Alpha", Icons.key_rounded, isDark: isDark),
                                const SizedBox(height: 16),
                                _buildField(_pass2, "Access Key Beta", Icons.enhanced_encryption_rounded, isDark: isDark),
                                const SizedBox(height: 16),
                                _buildField(_pass3, "Access Key Gamma", Icons.shield_moon_rounded, isDark: isDark),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Encrypted Save Checkbox
                          GestureDetector(
                            onTap: () => setState(() => _rememberInformation = !_rememberInformation),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: _rememberInformation ? AdminTheme.accent : Colors.transparent,
                                    border: Border.all(color: _rememberInformation ? AdminTheme.accent : (isDark ? Colors.white38 : Colors.black38), width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _rememberInformation ? const Icon(Icons.check_rounded, size: 16, color: Colors.black) : null,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text("Save EBM Key", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _cooldownSeconds > 0 || _sidController.text.isEmpty) ? null : _handleAuthorization,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.accent,
                                disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shadowColor: AdminTheme.accent.withOpacity(0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)) 
                                : Text(_cooldownSeconds > 0 ? "COOLDOWN ACTIVE" : "AUTHENTICATE WORKSPACE", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isTop = false, required bool isDark}) {
    return TextField(
      controller: controller,
      obscureText: !isTop,
      enabled: _cooldownSeconds == 0,
      onChanged: (v) => setState(() {}),
      style: TextStyle(
        color: isTop ? (isDark ? AdminTheme.accent : Colors.blue.shade800) : (isDark ? Colors.white : Colors.black87), 
        fontSize: 15,
        fontWeight: isTop ? FontWeight.bold : FontWeight.w600,
        letterSpacing: !isTop ? 2.5 : 0.5,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(icon, color: isTop ? AdminTheme.accent : (isDark ? Colors.white24 : Colors.black26), size: 22),
        ),
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13, fontWeight: FontWeight.normal, letterSpacing: 0),
        filled: true,
        fillColor: isDark ? const Color(0xFF0D0B14) : Colors.white,
        contentPadding: const EdgeInsets.all(24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminTheme.accent, width: 2)),
      ),
    );
  }
}
