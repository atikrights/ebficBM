import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionUtil {
  static final _key = Key.fromUtf8('ebm_enterprise_secure_vault_2026'); // Must match backend
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  static String encrypt(String text) {
    if (text.isEmpty) return '';
    return _encrypter.encrypt(text, iv: _iv).base64;
  }

  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return '';
    try {
      return _encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      return '[Decryption Error]';
    }
  }

  static String generateHash(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }
}
