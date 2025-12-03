import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/services/security_service.dart';
import 'package:expense_app_new/database/database.dart';

class BackupService {
  static const String _dbName = 'app_database.db';
  
  static Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbName));
  }

  static Future<void> createBackup({bool isManual = true}) async {
    final dbFile = await _getDbFile();
    if (!await dbFile.exists()) throw Exception('Database not found');

    // 1. Create Temp Copy using VACUUM INTO for atomic snapshot
    // This ensures we get a consistent state even if WAL mode is active
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempDbFile = File(p.join(tempDir.path, 'backup_temp.db'));
    
    // Ensure temp file doesn't exist
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }

    // Open a temporary connection to perform the backup
    final db = AppDatabase();
    try {
      // VACUUM INTO creates a consistent backup into the specified file
      await db.customStatement('VACUUM INTO ?', [tempDbFile.path]);
    } catch (e) {
      // Fallback for older SQLite versions or other errors: Checkpoint and Copy
      print('VACUUM INTO failed, falling back to Checkpoint + Copy: $e');
      try {
        await db.customStatement('PRAGMA wal_checkpoint(FULL)');
        await dbFile.copy(tempDbFile.path);
      } catch (e2) {
        throw Exception('Failed to create database backup: $e2');
      }
    } finally {
      await db.close();
    }
    
    try {
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
    } finally {
      // Cleanup temp files
      if (await tempDbFile.exists()) await tempDbFile.delete();
      // encryptedFile might be needed by Share, so we don't delete it immediately here if manual
      // But for auto backup we could. For simplicity, we let OS cleanup temp.
    }
  }

  static Future<void> restoreBackup(String filePath, AppDatabase db) async {
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
    // Close the active connection to prevent corruption
    try {
      await db.close();
    } catch (e) {
      print('Error closing database: $e');
      // Proceed anyway as we are replacing the file
    }

    try {
      final dbFile = await _getDbFile();
      await dbFile.writeAsBytes(await decryptedDbFile.readAsBytes());
    } finally {
      // Cleanup
      if (await decryptedDbFile.exists()) await decryptedDbFile.delete();
    }
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
