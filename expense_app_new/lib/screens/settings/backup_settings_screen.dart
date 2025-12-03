import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_app_new/services/backup_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/providers/database_provider.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  bool _autoBackupEnabled = false;
  String _backupFrequency = 'daily'; // daily, weekly, monthly
  List<File> _localBackups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackups();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      _backupFrequency = prefs.getString('auto_backup_frequency') ?? 'daily';
    });
  }

  Future<void> _loadBackups() async {
    final backups = await BackupService.getLocalBackups();
    setState(() => _localBackups = backups);
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', value);
    setState(() => _autoBackupEnabled = value);

    if (value) {
      _scheduleBackup();
    } else {
      Workmanager().cancelByUniqueName('autoBackup');
    }
  }

  Future<void> _changeFrequency(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_backup_frequency', value);
    setState(() => _backupFrequency = value);
    
    if (_autoBackupEnabled) {
      _scheduleBackup(); // Reschedule with new frequency
    }
  }

  void _scheduleBackup() {
    Duration frequency;
    switch (_backupFrequency) {
      case 'weekly': frequency = const Duration(days: 7); break;
      case 'monthly': frequency = const Duration(days: 30); break;
      case 'daily': default: frequency = const Duration(days: 1); break;
    }

    Workmanager().registerPeriodicTask(
      'autoBackup',
      'autoBackup',
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints( 
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      await BackupService.createBackup(isManual: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created and ready to share!')),
        );
      }
      _loadBackups(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() => _isLoading = true);
        final path = result.files.single.path!;
        
        // Get database instance to close it
        final db = ref.read(databaseProvider);
        await BackupService.restoreBackup(path, db);
        
        // Show success and restart dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Restore Successful'),
              content: const Text('Data restored successfully. The app needs to restart to apply changes.'),
              actions: [
                TextButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: const Text('Close App'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              _buildSectionHeader('Manual Backup'),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Create Backup'),
                subtitle: const Text('Encrypt and share your data'),
                onTap: _createBackup,
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Restore Backup'),
                subtitle: const Text('Restore from an encrypted file'),
                onTap: _restoreBackup,
              ),
              
              const Divider(),
              _buildSectionHeader('Automatic Backup'),
              SwitchListTile(
                title: const Text('Enable Auto-Backup'),
                subtitle: const Text('Back up locally to device storage'),
                value: _autoBackupEnabled,
                onChanged: _toggleAutoBackup,
              ),
              if (_autoBackupEnabled)
                ListTile(
                  title: const Text('Frequency'),
                  trailing: DropdownButton<String>(
                    value: _backupFrequency,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: _changeFrequency,
                  ),
                ),
                
              const Divider(),
              _buildSectionHeader('Local Backups'),
              if (_localBackups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No local backups found.', style: TextStyle(color: Colors.grey)),
                )
              else
                ..._localBackups.map((file) {
                  final date = file.lastModifiedSync();
                  final size = (file.lengthSync() / 1024).toStringAsFixed(1);
                  return ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(DateFormat.yMMMd().add_jm().format(date)),
                    subtitle: Text('${size} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        Share.shareXFiles([XFile(file.path)], text: 'My Expense Backup');
                      },
                    ),
                  );
                }),
            ],
          ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
