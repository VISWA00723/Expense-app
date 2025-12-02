import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/services/security_service.dart';

class BackupService {
  static const String _dbName = 'app_database.db';
  
  static Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbName));
  }

  static Future<void> createBackup({bool isManual = true}) async {
    final dbFile = await _getDbFile();
    if (!await dbFile.exists()) throw Exception('Database not found');

    // 1. Create Temp Copy
    // We copy to temp first to avoid locking issues (mostly) and to have a stable file to encrypt
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempDbFile = File(p.join(tempDir.path, 'backup_temp.db'));
    
    await dbFile.copy(tempDbFile.path);
    
    // 2. Encrypt
    final encryptedFile = File(p.join(tempDir.path, 'expense_backup_$timestamp.enc'));
    await SecurityService.encryptFile(tempDbFile, encryptedFile);
    
    // 3. Handle Output
    if (isManual) {
      await Share.shareXFiles([XFile(encryptedFile.path)], text: 'My Secure Expense Backup');
    } else {
      // Auto backup: Save to external storage (Android/data/...)
      final extDir = await getExternalStorageDirectory(); // Android/data/package/files
      if (extDir != null) {
        final backupDir = Directory(p.join(extDir.path, 'backups'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        final finalBackupFile = File(p.join(backupDir.path, 'auto_backup_$timestamp.enc'));
        await encryptedFile.copy(finalBackupFile.path);
        
        // Cleanup old backups (Keep last 5)
        await _cleanupOldBackups(backupDir);
      }
    }
    
    // Cleanup temp
    if (await tempDbFile.exists()) await tempDbFile.delete();
    // We keep encryptedFile in temp for a bit if shared, but OS cleans temp eventually.
  }

  static Future<void> restoreBackup(String filePath) async {
    final encryptedFile = File(filePath);
    if (!await encryptedFile.exists()) throw Exception('Backup file not found');

    final tempDir = await getTemporaryDirectory();
    final decryptedDbFile = File(p.join(tempDir.path, 'restore_temp.db'));

    // 1. Decrypt
    try {
      await SecurityService.decryptFile(encryptedFile, decryptedDbFile);
    } catch (e) {
      throw Exception('Decryption failed. Invalid key or corrupt file.');
    }

    // 2. Validate (Simple check: is it a valid SQLite file? Header 'SQLite format 3')
    try {
      final header = await decryptedDbFile.openRead(0, 16).first;
      final headerString = String.fromCharCodes(header);
      if (!headerString.startsWith('SQLite format 3')) {
        throw Exception('Invalid database format');
      }
    } catch (e) {
      throw Exception('Invalid backup file');
    }

    // 3. Replace DB
    final dbFile = await _getDbFile();
    
    // Note: This requires the app to be restarted to re-open the DB connection properly.
    // The UI should handle the restart prompt.
    await dbFile.writeAsBytes(await decryptedDbFile.readAsBytes());
    
    // Cleanup
    if (await decryptedDbFile.exists()) await decryptedDbFile.delete();
  }

  static Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = backupDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.enc'))
          .toList();
      
      if (files.length > 5) {
        // Sort by modification time (oldest first)
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // Delete oldest
        final toDelete = files.take(files.length - 5);
        for (final f in toDelete) {
          await f.delete();
        }
      }
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }
  
  static Future<List<File>> getLocalBackups() async {
    final extDir = await getExternalStorageDirectory();
    if (extDir == null) return [];
    
    final backupDir = Directory(p.join(extDir.path, 'backups'));
    if (!await backupDir.exists()) return [];
    
    final files = backupDir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.enc'))
        .toList();
        
    // Sort newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
