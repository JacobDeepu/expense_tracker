import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service to manage daily expense reminder notifications
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const int _notificationId = 1001;
  static const String _channelId = 'daily_reminder_channel_v2';
  static const String _channelName = 'Daily Expense Reminder';
  static const String _channelDesc = 'Reminds you to log your daily expenses';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Stream for notification tap events
  final _notificationTapController = StreamController<String>.broadcast();
  Stream<String> get onTap => _notificationTapController.stream;

  /// Initialize notification system
  Future<void> initializeNotifications() async {
    // Always ensure timezone is set, even if notifications are already initialized
    try {
      tz.initializeTimeZones();
      final dynamic deviceTimezone = await FlutterTimezone.getLocalTimezone();
      final String zoneName = deviceTimezone is String
          ? deviceTimezone
          : deviceTimezone.identifier.toString();

      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (e) {
      debugPrint('Timezone config failed, using UTC: $e');
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    if (_initialized) return;

    try {
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
      debugPrint('Notification plugin initialized');
    } catch (e) {
      debugPrint('Failed to initialize notification plugin: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      _notificationTapController.add(response.payload!);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // For Android 13+
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('Notification permission denied');
        return false;
      }
    }

    // For Android 12+ - exact alarm permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        debugPrint('Exact alarm permission denied');
        return false;
      }
    }

    return true;
  }

  /// Schedule daily reminder at specific time
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await initializeNotifications();

    // Request permissions first
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('Cannot schedule: Permissions denied');
      return;
    }

    try {
      // Cancel any existing reminders
      await cancelReminder();

      // Get next instance of time within local timezone
      final scheduledDate = _nextInstanceOfTime(time);

      debugPrint(
        'Scheduling Reminder: ${time.hour}:${time.minute.toString().padLeft(2, '0')} (Local) at $scheduledDate on $_channelId',
      );

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule daily repeating notification
      await _notifications.zonedSchedule(
        _notificationId,
        'Time to log your expenses! 💰',
        'Track your spending to stay on budget',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'daily_entry',
      );

      debugPrint('Reminder successfully scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Calculate the next instance of the given time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel scheduled reminder
  Future<void> cancelReminder() async {
    await _notifications.cancel(_notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Schedule a test notification 10 seconds from now
  Future<void> scheduleTestReminder() async {
    await initializeNotifications();

    // 10 seconds from now
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = now.add(const Duration(seconds: 10));

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _notificationId + 1, // Different ID used for test
      'Scheduled Test',
      'This notification was scheduled 10s ago.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_entry-test',
    );

    debugPrint('Test reminder scheduled for $scheduledDate');
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
