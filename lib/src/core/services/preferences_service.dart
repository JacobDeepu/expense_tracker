import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to manage app preferences and settings
class PreferencesService {
  static const String _reminderTimeKey = 'reminder_time';
  static const String _lastLoggedDateKey = 'last_logged_date';
  static const String _reminderSetKey = 'reminder_set';
  static const String _monthlyBudgetKey = 'monthly_budget';

  /// Save reminder time (stored as minutes since midnight)
  Future<void> saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final minutesSinceMidnight = time.hour * 60 + time.minute;
    await prefs.setInt(_reminderTimeKey, minutesSinceMidnight);
    await prefs.setBool(_reminderSetKey, true);
  }

  /// Get saved reminder time
  Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final minutesSinceMidnight = prefs.getInt(_reminderTimeKey);

    if (minutesSinceMidnight == null) return null;

    final hours = minutesSinceMidnight ~/ 60;
    final minutes = minutesSinceMidnight % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  /// Check if reminder has been set up
  Future<bool> isReminderSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderSetKey) ?? false;
  }

  /// Save monthly budget
  Future<void> saveMonthlyBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyBudgetKey, amount);
  }

  /// Get monthly budget
  Future<double?> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyBudgetKey);
  }

  /// Save last logged date (mock for Phase 2)
  Future<void> saveLastLoggedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoggedDateKey, date.toIso8601String());
  }

  /// Get last logged date
  Future<DateTime?> getLastLoggedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastLoggedDateKey);

    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  /// Check if user has logged expenses today (mock)
  Future<bool> hasLoggedToday() async {
    final lastLogged = await getLastLoggedDate();

    if (lastLogged == null) return false;

    final now = DateTime.now();
    return lastLogged.year == now.year &&
        lastLogged.month == now.month &&
        lastLogged.day == now.day;
  }

  /// Check if current time is after reminder time
  Future<bool> isAfterReminderTime() async {
    final reminderTime = await getReminderTime();
    if (reminderTime == null) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final reminderMinutes = reminderTime.hour * 60 + reminderTime.minute;

    return nowMinutes >= reminderMinutes;
  }
}

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});