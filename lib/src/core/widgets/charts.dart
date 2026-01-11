import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Segmented ring chart for budget overview
/// Shows: Fixed expenses (gray), Spent (colored), Remaining (empty)
class SegmentedRingChart extends StatefulWidget {
  final double totalBudget;
  final double fixedExpenses;
  final double variableSpent;
  final Color fixedColor;
  final Color spentColor;
  final Color remainingColor;

  const SegmentedRingChart({
    required this.totalBudget,
    required this.fixedExpenses,
    required this.variableSpent,
    this.fixedColor = const Color(0xFF9CA3AF), // Gray-400
    this.spentColor = const Color(0xFF3B82F6), // Blue-500
    this.remainingColor = const Color(0xFFE5E7EB), // Gray-200
    super.key,
  });

  @override
  State<SegmentedRingChart> createState() => _SegmentedRingChartState();
}

class _SegmentedRingChartState extends State<SegmentedRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _SegmentedRingPainter(
              totalBudget: widget.totalBudget,
              fixedExpenses: widget.fixedExpenses,
              variableSpent: widget.variableSpent,
              fixedColor: isDark ? widget.fixedColor : const Color(0xFF6B7280),
              spentColor: isDark
                  ? AppColors.signalBlueDark
                  : AppColors.signalBlueLight,
              remainingColor: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFE5E7EB),
              progress: _animation.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${((widget.fixedExpenses + widget.variableSpent) / widget.totalBudget * 100 * _animation.value).toInt()}%',
                    style: AppTypography.displayL(textPrimary),
                  ),
                  Text('used', style: AppTypography.caption(textSecondary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final double totalBudget;
  final double fixedExpenses;
  final double variableSpent;
  final Color fixedColor;
  final Color spentColor;
  final Color remainingColor;
  final double progress;

  _SegmentedRingPainter({
    required this.totalBudget,
    required this.fixedExpenses,
    required this.variableSpent,
    required this.fixedColor,
    required this.spentColor,
    required this.remainingColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2; // Start from top

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate sweep angles
    final fixedSweep = (fixedExpenses / totalBudget) * 2 * math.pi * progress;
    final spentSweep = (variableSpent / totalBudget) * 2 * math.pi * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw remaining (background)
    paint.color = remainingColor;
    canvas.drawArc(rect, startAngle, 2 * math.pi, false, paint);

    // Draw fixed expenses
    paint.color = fixedColor;
    canvas.drawArc(rect, startAngle, fixedSweep, false, paint);

    // Draw variable spent
    paint.color = spentColor;
    canvas.drawArc(rect, startAngle + fixedSweep, spentSweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Horizontal bar chart for category spending
class HorizontalBarChart extends StatelessWidget {
  final List<CategoryBarData> data;
  final double maxValue;

  const HorizontalBarChart({
    required this.data,
    required this.maxValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bgColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Column(
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final barWidth = maxValue > 0 ? (item.amount / maxValue) : 0.0;

        return Padding(
          padding: EdgeInsets.only(bottom: index < data.length - 1 ? 16 : 0),
          child: _AnimatedBarRow(
            index: index,
            label: item.label,
            amount: item.amount,
            color: item.color,
            barWidth: barWidth,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            bgColor: bgColor,
          ),
        );
      }).toList(),
    );
  }
}

class _AnimatedBarRow extends StatefulWidget {
  final int index;
  final String label;
  final double amount;
  final Color color;
  final double barWidth;
  final Color textPrimary;
  final Color textSecondary;
  final Color bgColor;

  const _AnimatedBarRow({
    required this.index,
    required this.label,
    required this.amount,
    required this.color,
    required this.barWidth,
    required this.textPrimary,
    required this.textSecondary,
    required this.bgColor,
  });

  @override
  State<_AnimatedBarRow> createState() => _AnimatedBarRowState();
}

class _AnimatedBarRowState extends State<_AnimatedBarRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.barWidth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: AppTypography.bodyM(widget.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: AppTypography.bodyMTabular(widget.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _widthAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryBarData {
  final String label;
  final double amount;
  final Color color;

  const CategoryBarData({
    required this.label,
    required this.amount,
    required this.color,
  });
}
