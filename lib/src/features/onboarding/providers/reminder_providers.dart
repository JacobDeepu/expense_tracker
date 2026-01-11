import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import '../../../core/services/reminder_service.dart';

/// Provider for preferences service
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Provider for reminder service
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// Provider to check if user has logged today (mock)
final hasLoggedTodayProvider = FutureProvider<bool>((ref) async {
  final prefsService = ref.watch(preferencesServiceProvider);
  return await prefsService.hasLoggedToday();
});

/// Provider to check if should show transaction card automatically
final shouldShowTransactionCardProvider = FutureProvider<bool>((ref) async {
  final prefsService = ref.watch(preferencesServiceProvider);

  // Check if reminder is set
  final isReminderSet = await prefsService.isReminderSet();
  if (!isReminderSet) return false;

  // Check if current time is after reminder time
  final isAfterReminder = await prefsService.isAfterReminderTime();
  if (!isAfterReminder) return false;

  // Check if user has already logged today
  final hasLogged = await prefsService.hasLoggedToday();
  return !hasLogged; // Show card if NOT logged yet
});
