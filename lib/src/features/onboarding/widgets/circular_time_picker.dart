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
    // Each hour = 30 degrees, each minute = 6 degrees
    return ((_hour % 12) * 30.0) + (_minute * 0.5);
  }

  void _angleToTime(double angle) {
    // Normalize angle to 0-360
    angle = angle % 360;
    if (angle < 0) angle += 360;

    // Convert angle to time
    // Each 30 degrees = 1 hour, each 6 degrees = 1 minute
    final totalMinutes = (angle * 2)
        .round(); // 360 degrees = 720 minutes (12 hours)
    _hour = (totalMinutes ~/ 60) % 24;
    _minute = totalMinutes % 60;

    // Round to nearest 5 minutes for better UX
    _minute = (_minute ~/ 5) * 5;

    widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition - center;
    final newAngle = math.atan2(position.dy, position.dx) * 180 / math.pi + 90;

    setState(() {
      _angle = newAngle;
      _angleToTime(_angle);
    });

    // Haptic feedback every 5 degrees (every 10 minutes)
    if ((_angle % 15).abs() < 1) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!_isDragging) {
          setState(() => _isDragging = true);
          HapticFeedback.mediumImpact();
        }
        _handlePanUpdate(details, Size(300, 300));
      },
      onPanEnd: (_) {
        setState(() => _isDragging = false);
        HapticFeedback.lightImpact();
      },
      child: CustomPaint(
        size: const Size(300, 300),
        painter: _CircularTimePickerPainter(
          angle: _angle,
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
