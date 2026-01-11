import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/preferences_service.dart';
import '../providers/reminder_providers.dart';
import '../widgets/circular_time_picker.dart';

class ReminderTimeScreen extends ConsumerStatefulWidget {
  const ReminderTimeScreen({super.key});

  @override
  ConsumerState<ReminderTimeScreen> createState() => _ReminderTimeScreenState();
}

class _ReminderTimeScreenState extends ConsumerState<ReminderTimeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(
    hour: 21,
    minute: 0,
  ); // Default 9 PM

  Future<void> _saveAndContinue() async {
    debugPrint(
      'Saving reminder time: ${_selectedTime.hour}:${_selectedTime.minute}',
    );

    final prefsService = ref.read(preferencesServiceProvider);
    final reminderService = ref.read(reminderServiceProvider);

    // Save reminder time
    await prefsService.saveReminderTime(_selectedTime);
    debugPrint('Reminder time saved');

    // Schedule daily notification
    await reminderService.scheduleDailyReminder(_selectedTime);
    debugPrint('Notification scheduled (or skipped if permission denied)');

    if (mounted) {
      debugPrint('Navigating to dashboard');
      context.go(RouteNames.dashboard);
    }
  }

  void _skip() {
    debugPrint('Skipping reminder setup');
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final signalBlue = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;
    final surfaceSecondary = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),

                // Header
                Text(
                  'DAILY REMINDER',
                  style: AppTypography.captionUppercase(textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your reminder time',
                  style: AppTypography.displayL(textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rotate the ring to set your time',
                  style: AppTypography.bodyM(textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 80),

                // Circular Time Picker
                CircularTimePicker(
                  initialTime: _selectedTime,
                  onTimeChanged: (time) {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                  activeColor: signalBlue,
                  inactiveColor: surfaceSecondary,
                  textColor: textPrimary,
                ),

                const SizedBox(height: 80),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('Continue button tapped');
                      await _saveAndContinue();
                    },
                    child: const Text('Continue'),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip Button
                Center(
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip for now',
                      style: AppTypography.bodyM(textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
