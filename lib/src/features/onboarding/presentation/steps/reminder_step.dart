import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/preferences_service.dart';
import '../../providers/reminder_providers.dart';

class ReminderStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<LinearGradient> onGradientChanged;

  const ReminderStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onGradientChanged,
  });

  @override
  ConsumerState<ReminderStep> createState() => _ReminderStepState();
}

class _ReminderStepState extends ConsumerState<ReminderStep> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  // Gesture handling state
  double _hourDragAccumulator = 0.0;
  double _minuteDragAccumulator = 0.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default time gradient on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        widget.onGradientChanged(_getBackgroundGradient());
        _initialized = true;
      }
    });
  }

  Future<void> _saveAndContinue() async {
    final prefsService = ref.read(preferencesServiceProvider);
    final reminderService = ref.read(reminderServiceProvider);

    try {
      await reminderService.requestPermissions();
      await prefsService.saveReminderTime(_selectedTime);
      await reminderService.scheduleDailyReminder(_selectedTime);
    } catch (e) {
      debugPrint('Error during reminder setup: $e');
    }

    widget.onNext();
  }

  void _updateTime(double dy, {bool isHour = true}) {
    // Sensitivity: how many pixels to drag to change one unit
    const sensitivity = 20.0;

    // Reverse logic: Drag up (negative dy) = increase time
    final deltaChange = -dy;

    if (isHour) {
      _hourDragAccumulator += deltaChange;
      while (_hourDragAccumulator.abs() > sensitivity) {
        int delta = _hourDragAccumulator > 0 ? 1 : -1;
        _hourDragAccumulator -= delta * sensitivity;

        setState(() {
          int newHour = (_selectedTime.hour + delta) % 24;
          if (newHour < 0) newHour += 24;
          _selectedTime = _selectedTime.replacing(hour: newHour);
        });
        HapticFeedback.selectionClick();
        widget.onGradientChanged(_getBackgroundGradient());
      }
    } else {
      _minuteDragAccumulator += deltaChange;
      while (_minuteDragAccumulator.abs() > sensitivity) {
        int delta = _minuteDragAccumulator > 0 ? 5 : -5;
        _minuteDragAccumulator -= (delta / 5) * sensitivity;

        setState(() {
          int newMinute = (_selectedTime.minute + delta) % 60;
          if (newMinute < 0) newMinute += 60;
          _selectedTime = _selectedTime.replacing(minute: newMinute);
        });
        HapticFeedback.selectionClick();
      }
    }
  }

  LinearGradient _getBackgroundGradient() {
    final hour = _selectedTime.hour;

    // Night (20-4)
    if (hour >= 20 || hour < 4) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      );
    }
    // Dawn (4-8)
    if (hour >= 4 && hour < 8) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4338CA), Color(0xFFF472B6)],
      );
    }
    // Day (8-16)
    if (hour >= 8 && hour < 16) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD)],
      );
    }
    // Dusk (16-20)
    if (hour >= 16 && hour < 20) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF97316), Color(0xFF7C3AED)],
      );
    }
    return const LinearGradient(colors: [Colors.black, Colors.black]);
  }

  String _getGreeting() {
    final hour = _selectedTime.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Sweet Dreams';
  }

  Color _getTextColor() {
    final hour = _selectedTime.hour;
    if (hour >= 8 && hour < 16) return Colors.black.withValues(alpha: 0.8);
    return Colors.white.withValues(alpha: 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();
    // No gradients here, parent handles it.

    return Column(
      children: [
        const SizedBox(height: 32),

        // Header
        Text(
          'REMINDER',
          style: AppTypography.captionUppercase(
            textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(_getGreeting(), style: AppTypography.headingM(textColor)),

        const Spacer(),

        // Time Picker Display
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hours
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) =>
                    _updateTime(details.delta.dy, isHour: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 24,
                  ),
                  child: Text(
                    _selectedTime.hourOfPeriod.toString().padLeft(2, '0'),
                    style: AppTypography.displayXL(
                      textColor,
                    ).copyWith(fontSize: 88),
                  ),
                ),
              ),

              Text(
                ':',
                style: AppTypography.displayXL(
                  textColor,
                ).copyWith(fontSize: 88, height: 0.8),
              ),

              // Minutes
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) =>
                    _updateTime(details.delta.dy, isHour: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 24,
                  ),
                  child: Text(
                    _selectedTime.minute.toString().padLeft(2, '0'),
                    style: AppTypography.displayXL(
                      textColor,
                    ).copyWith(fontSize: 88),
                  ),
                ),
              ),

              // AM/PM
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AM',
                      style: AppTypography.headingS(
                        _selectedTime.period == DayPeriod.am
                            ? textColor
                            : textColor.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PM',
                      style: AppTypography.headingS(
                        _selectedTime.period == DayPeriod.pm
                            ? textColor
                            : textColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Drag numbers up or down to adjust',
          style: AppTypography.bodyM(textColor.withValues(alpha: 0.7)),
        ),

        const Spacer(),

        // Continue Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor, // Use text color (Contrast)
                foregroundColor:
                    _getBackgroundGradient().colors.first, // Use bg color
                elevation: 0,
                padding: EdgeInsets.zero, // Fix for cut-off text
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Done',
                style: AppTypography.headingS(
                  _getBackgroundGradient().colors.first,
                ).copyWith(height: 1.0), // Reset height
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
