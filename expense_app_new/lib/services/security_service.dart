import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // 32 bytes = 256 bits
  // Obfuscated key construction to avoid simple string grep
  // NOTE: In a real production app with higher security needs, 
  // this should be derived from a user password or stored in Android Keystore.
  // For this requirement ("App-only decryption" + portability), a fixed key is used.
  static final _keyParts = [
    'E', 'x', 'p', 'e', 'n', 's', 'e', 'A',
    'p', 'p', 'S', 'e', 'c', 'u', 'r', 'e',
    'K', 'e', 'y', '2', '0', '2', '4', '!',
    '@', '#', '\$', '%', '^', '&', '*', '('
  ];
  
  static encrypt.Key get _key => encrypt.Key.fromUtf8(_keyParts.join(''));
  
  // Use a per-encryption random IV and prepend it to the ciphertext.
  // Key is fixed for "app-only" decryption; for stronger security, derive it
  // from user credentials or Android Keystore.
  
  static Future<void> encryptFile(File inputFile, File outputFile) async {
    // TODO: For large backup files, consider moving to a streaming API (chunked read/encrypt/write) to keep memory usage predictable.
    final fileBytes = await inputFile.readAsBytes();
    
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    
    // Write IV + Encrypted Data
    final combined = <int>[...iv.bytes, ...encrypted.bytes];
    await outputFile.writeAsBytes(combined);
  }

  static Future<void> decryptFile(File inputFile, File outputFile) async {
    final fileBytes = await inputFile.readAsBytes();
    
    if (fileBytes.length < 16) {
      throw FormatException('Encrypted file is too short to contain IV and ciphertext');
    }

    // Extract IV (first 16 bytes)
    final ivBytes = fileBytes.sublist(0, 16);
    final encryptedBytes = fileBytes.sublist(16);
    
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    
    await outputFile.writeAsBytes(decrypted);
  }
}
