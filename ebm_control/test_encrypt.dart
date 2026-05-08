import 'package:encrypt/encrypt.dart';

void main() {
  final keyStr = "ebfic-ebm-central-secure-key-32b";
  final key = Key.fromUtf8(keyStr);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  final rawData = "admin@ebfic.store|||ebfic|||admin|||786";
  try {
     final encrypted = encrypter.encrypt(rawData, iv: iv);
     print("Encrypted: \${encrypted.base64}");
     final decrypted = encrypter.decrypt64(encrypted.base64, iv: iv);
     print("Decrypted: \$decrypted");
  } catch (e) {
     print("Error: \$e");
  }
}
