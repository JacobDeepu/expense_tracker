import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/reminder_service.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});
