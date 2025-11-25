import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static const String _enabledKey = 'notifications_enabled';

  // Notification times
  static const int morningHour = 9;
  static const int afternoonHour = 15;
  static const int nightHour = 21;

  // Motivational messages (fallback if AI fails)
  static final List<String> _morningMessages = [
    "Good morning! 🌅 Ready to track today's expenses?",
    "Rise and shine! ☀️ Let's make today financially smart!",
    "Morning! 🌞 A penny saved is a penny earned!",
    "New day, new budget! 💰 Track your expenses today!",
  ];

  static final List<String> _afternoonMessages = [
    "Hey! Don't forget to log that lunch expense 🍽️",
    "Afternoon check-in! 📊 How's your budget looking?",
    "Quick reminder! 💡 Track your expenses as you go!",
    "Halfway through the day! 🕐 Keep those receipts handy!",
  ];

  static final List<String> _nightMessages = [
    "Before bed, did you track all your expenses today? 😴",
    "Good night! 🌙 Don't forget today's expenses!",
    "End of day reminder! 📝 Log your expenses now!",
    "Sweet dreams! 💤 But first, update your expense tracker!",
  ];

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Android initialization with notification channel
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'daily_reminders',
      'Daily Reminders',
      description: 'Daily expense tracking reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // App is already open, just log the tap
  }

  static Future<bool> requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true; // Default enabled
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    
    if (enabled) {
      await scheduleDailyNotifications();
    } else {
      await cancelAllNotifications();
    }
  }

  static Future<void> scheduleDailyNotifications() async {
    if (!await isEnabled()) return;

    // Check if we have exact alarm permission (Android 12+)
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      
      if (canSchedule == false) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    await cancelAllNotifications();

    // Schedule morning notification
    await _scheduleNotification(
      id: 1,
      hour: morningHour,
      minute: 0,
      title: 'Good Morning! 🌅',
      body: _getRandomMessage(_morningMessages),
    );

    // Schedule afternoon notification
    await _scheduleNotification(
      id: 2,
      hour: afternoonHour,
      minute: 0,
      title: 'Afternoon Reminder 📊',
      body: _getRandomMessage(_afternoonMessages),
    );

    // Schedule night notification
    await _scheduleNotification(
      id: 3,
      hour: nightHour,
      minute: 0,
      title: 'Good Night! 🌙',
      body: _getRandomMessage(_nightMessages),
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily expense tracking reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
