import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Budget overview card with mini animated ring chart
class BudgetOverviewCard extends StatelessWidget {
  final double monthlyBudget;
  final double fixedExpenses;
  final double variableSpent;

  const BudgetOverviewCard({
    required this.monthlyBudget,
    required this.fixedExpenses,
    required this.variableSpent,
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
    final signalBlue = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;

    final remaining = monthlyBudget - fixedExpenses - variableSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceSecondaryDark
            : AppColors.surfacePrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Mini Ring Chart
          _MiniRingChart(
            totalBudget: monthlyBudget,
            fixedExpenses: fixedExpenses,
            variableSpent: variableSpent,
            isDark: isDark,
          ),
          const SizedBox(width: 20),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.wallet, size: 16, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Budget',
                      style: AppTypography.caption(
                        textSecondary,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_formatAmount(remaining)}',
                  style: AppTypography.displayL(
                    textPrimary,
                  ).copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining >= 0 ? 'remaining' : 'over budget',
                  style: AppTypography.caption(
                    remaining >= 0
                        ? (isDark
                              ? AppColors.insightPositiveDark
                              : AppColors.insightPositiveLight)
                        : (isDark
                              ? AppColors.signalRedDark
                              : AppColors.signalRedLight),
                  ),
                ),
                const SizedBox(height: 12),
                // Mini legend row
                Row(
                  children: [
                    _LegendDot(color: const Color(0xFF6B7280), label: 'Fixed'),
                    const SizedBox(width: 12),
                    _LegendDot(color: signalBlue, label: 'Spent'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final absAmount = amount.abs();
    if (absAmount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _MiniRingChart extends StatefulWidget {
  final double totalBudget;
  final double fixedExpenses;
  final double variableSpent;
  final bool isDark;

  const _MiniRingChart({
    required this.totalBudget,
    required this.fixedExpenses,
    required this.variableSpent,
    required this.isDark,
  });

  @override
  State<_MiniRingChart> createState() => _MiniRingChartState();
}

class _MiniRingChartState extends State<_MiniRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    final usedPercent =
        ((widget.fixedExpenses + widget.variableSpent) /
                widget.totalBudget *
                100)
            .clamp(0.0, 100.0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _MiniRingPainter(
              totalBudget: widget.totalBudget,
              fixedExpenses: widget.fixedExpenses,
              variableSpent: widget.variableSpent,
              progress: _animation.value,
              isDark: widget.isDark,
            ),
            child: Center(
              child: Text(
                '${(usedPercent * _animation.value).toInt()}%',
                style: AppTypography.bodyM(
                  widget.isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double totalBudget;
  final double fixedExpenses;
  final double variableSpent;
  final double progress;
  final bool isDark;

  _MiniRingPainter({
    required this.totalBudget,
    required this.fixedExpenses,
    required this.variableSpent,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final fixedSweep = (fixedExpenses / totalBudget) * 2 * math.pi * progress;
    final spentSweep = (variableSpent / totalBudget) * 2 * math.pi * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background
    paint.color = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    canvas.drawArc(rect, startAngle, 2 * math.pi, false, paint);

    // Fixed
    paint.color = const Color(0xFF6B7280);
    canvas.drawArc(rect, startAngle, fixedSweep, false, paint);

    // Variable spent
    paint.color = isDark ? AppColors.signalBlueDark : AppColors.signalBlueLight;
    canvas.drawArc(rect, startAngle + fixedSweep, spentSweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
