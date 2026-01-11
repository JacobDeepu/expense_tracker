import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Circular watch-style time picker with rotation gesture
class CircularTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;

  const CircularTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
  });

  @override
  State<CircularTimePicker> createState() => _CircularTimePickerState();
}

class _CircularTimePickerState extends State<CircularTimePicker> {
  late int _hour;
  late int _minute;
  double _angle = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _angle = _timeToAngle();
  }

  double _timeToAngle() {
    // Convert time to angle (0-360 degrees)
    // 12-hour clock face
    final hour12 = _hour % 12;
    return ((hour12 * 30.0) + (_minute * 0.5));
  }

  void _angleToTime(double angle) {
    // Normalize angle to 0-360
    double normalizedAngle = angle % 360;
    if (normalizedAngle < 0) normalizedAngle += 360;

    // Convert angle to time (12h format)
    // Each 30 degrees = 1 hour, each 0.5 degrees = 1 minute
    final totalMinutes = (normalizedAngle * 2).round();
    
    int newHour = (totalMinutes ~/ 60) % 12;
    int newMinute = totalMinutes % 60;
    
    // Round to nearest 5 minutes
    newMinute = (newMinute ~/ 5) * 5;

    // Preserve AM/PM from current state
    final isPm = _hour >= 12;
    if (isPm && newHour < 12) newHour += 12;
    if (!isPm && newHour == 12) newHour = 0; // Handle midnight edge case if needed

    _hour = newHour;
    _minute = newMinute;

    widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition - center;
    
    // Calculate angle in degrees (0 at top/12 o'clock)
    // atan2 returns radians from -pi to pi (0 at right/3 o'clock)
    double newAngle = math.atan2(position.dy, position.dx) * 180 / math.pi;
    
    // Shift so 0 is at top (-90 degrees in atan2)
    newAngle += 90;
    
    if (newAngle < 0) newAngle += 360;

    setState(() {
      _angle = newAngle;
      _angleToTime(_angle);
    });

    // Haptic feedback
    if ((_angle % 15).abs() < 2) { // increased threshold slightly
      HapticFeedback.selectionClick();
    }
  }

  void _toggleAmPm() {
    setState(() {
      if (_hour >= 12) {
        _hour -= 12;
      } else {
        _hour += 12;
      }
      widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Add tap gesture for AM/PM toggle
    return GestureDetector(
      onPanUpdate: (details) {
        if (!_isDragging) {
          setState(() => _isDragging = true);
          HapticFeedback.mediumImpact();
        }
        _handlePanUpdate(details, const Size(300, 300));
      },
      onPanEnd: (_) {
        setState(() => _isDragging = false);
        HapticFeedback.lightImpact();
      },
      onTapUp: (details) {
        // Simple hit test for center area to toggle AM/PM
        final center = const Offset(150, 150); // Half of 300
        if ((details.localPosition - center).distance < 60) {
          _toggleAmPm();
        }
      },
      child: CustomPaint(
        size: const Size(300, 300),
        painter: _CircularTimePickerPainter(
          angle: _timeToAngle(), // Always use time to drive angle for consistency
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          textColor: widget.textColor,
          hour: _hour,
          minute: _minute,
          isDragging: _isDragging,
        ),
      ),
    );
  }
}

class _CircularTimePickerPainter extends CustomPainter {
  final double angle;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;
  final int hour;
  final int minute;
  final bool isDragging;

  _CircularTimePickerPainter({
    required this.angle,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
    required this.hour,
    required this.minute,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;

    // Draw outer ring (inactive)
    final ringPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, ringPaint);

    // Draw active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final sweepAngle = angle * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle,
      false,
      activePaint,
    );

    // Draw hour markers
    for (int i = 0; i < 12; i++) {
      final markerAngle = (i * 30 - 90) * math.pi / 180;
      final markerStart = Offset(
        center.dx + (radius - 12) * math.cos(markerAngle),
        center.dy + (radius - 12) * math.sin(markerAngle),
      );
      final markerEnd = Offset(
        center.dx + (radius + 12) * math.cos(markerAngle),
        center.dy + (radius + 12) * math.sin(markerAngle),
      );

      final markerPaint = Paint()
        ..color = textColor.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(markerStart, markerEnd, markerPaint);
    }

    // Draw thumb (draggable indicator)
    final thumbAngle = (angle - 90) * math.pi / 180;
    final thumbPosition = Offset(
      center.dx + radius * math.cos(thumbAngle),
      center.dy + radius * math.sin(thumbAngle),
    );

    // Outer glow when dragging
    if (isDragging) {
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(thumbPosition, 24, glowPaint);
    }

    // Thumb circle
    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(thumbPosition, 16, thumbPaint);

    // Thumb border
    final thumbBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(thumbPosition, 16, thumbBorderPaint);

    // Draw center time display
    final timeText =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeText,
        style: TextStyle(
          color: textColor,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Draw period (AM/PM) below time
    final period = hour < 12 ? 'AM' : 'PM';
    final periodPainter = TextPainter(
      text: TextSpan(
        text: period,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    periodPainter.layout();
    periodPainter.paint(
      canvas,
      Offset(center.dx - periodPainter.width / 2, center.dy + 30),
    );
  }

  @override
  bool shouldRepaint(_CircularTimePickerPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.hour != hour ||
        oldDelegate.minute != minute;
  }
}
