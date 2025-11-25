import 'package:flutter/material.dart';
import 'package:expense_app_new/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionDialog {
  static const String _shownKey = 'notification_permission_shown';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_shownKey) ?? false;

    if (hasShown) return;

    // Mark as shown
    await prefs.setBool(_shownKey, true);

    if (!context.mounted) return;

    // Show dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active, size: 48),
        title: const Text('Stay on Track! 📊'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get daily reminders to track your expenses at:',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeChip(icon: Icons.wb_sunny, time: '9 AM'),
                _TimeChip(icon: Icons.wb_cloudy, time: '3 PM'),
                _TimeChip(icon: Icons.nightlight_round, time: '9 PM'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'You can change this anytime in Profile settings.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await NotificationService.requestPermission();
              if (granted) {
                await NotificationService.setEnabled(true);
                await NotificationService.scheduleDailyNotifications();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Notifications enabled! You\'ll receive 3 daily reminders.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Enable Reminders'),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;

  const _TimeChip({required this.icon, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
