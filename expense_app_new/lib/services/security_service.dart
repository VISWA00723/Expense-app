import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // ... (existing code) ...

  static Future<void> decryptFile(File inputFile, File outputFile) async {
    final fileBytes = await inputFile.readAsBytes();
    
    if (fileBytes.length < 16) {
      throw FormatException('Encrypted file is too short to contain IV and ciphertext');
    }

    // Extract IV (first 16 bytes)
    final ivBytes = Uint8List.fromList(fileBytes.sublist(0, 16));
    final encryptedBytes = Uint8List.fromList(fileBytes.sublist(16));
    
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    
    await outputFile.writeAsBytes(decrypted);
  }
}
