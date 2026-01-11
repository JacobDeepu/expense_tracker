import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service to manage daily expense reminder notifications
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification system
  Future<void> initializeNotifications() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to transaction input when notification is tapped
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // For Android 13+
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Schedule daily reminder at specific time
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await initializeNotifications();

    // Request permissions first
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('Notification permission denied');
      return;
    }

    // Cancel any existing reminders
    await cancelReminder();

    // Create notification time for today
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Expense Reminder',
      channelDescription: 'Reminds you to log your daily expenses',
      importance: Importance.high,
      priority: Priority.high,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily repeating notification
    try {
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Time to log your expenses! 💰',
        'Track your spending to stay on budget',
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );

      debugPrint('Daily reminder scheduled for ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      // Continue anyway - user can still use the app without notifications
    }
  }

  /// Cancel scheduled reminder
  Future<void> cancelReminder() async {
    await _notifications.cancel(0);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
