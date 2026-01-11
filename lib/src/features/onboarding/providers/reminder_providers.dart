import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ReminderService() {
    _initialize();
  }

  Future<void> _initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // On iOS, we can defer permission request until later by setting these to false
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap logic here
      },
    );
  }

  Future<bool> requestPermissions() async {
    // 1. Try Permission Handler (Covers Android 13+ and iOS)
    final status = await Permission.notification.request();
    
    // 2. For iOS specific (via plugin if needed, but permission_handler usually works)
    // If we wanted to use the plugin method:
    // final iOSImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    // await iOSImplementation?.requestPermissions(alert: true, badge: true, sound: true);

    return status.isGranted;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    // Ensure we have permission or at least try
    // (In a real app, we might check status first, but scheduling without permission usually just fails silently or logs warning)
    
    try {
      await _notificationsPlugin.cancelAll(); // Cancel existing

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
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

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Daily Spending Check',
        channelDescription: 'Reminds you to record cash spending',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        0,
        'Did you spend cash today?',
        'Take 5 seconds to record it.',
        scheduledDate,
        details,
        // Use inexact to avoid SCHEDULE_EXACT_ALARM permission crash on Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});