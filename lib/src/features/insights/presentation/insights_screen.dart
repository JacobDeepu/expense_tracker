import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/services/preferences_service.dart';
import '../../onboarding/data/recurring_rules_repository.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final signalBlue = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;

    final categorySpendingAsync = ref.watch(categorySpendingProvider);
    final weeklySpendingAsync = ref.watch(weeklySpendingProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
        ),
        title: Text('Insights', style: AppTypography.headingM(textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Overview with Segmented Ring
            SlideInAnimation(
              index: 0,
              child: _buildBudgetRingSection(
                context,
                ref,
                isDark,
                textPrimary,
                textSecondary,
                surface,
              ),
            ),

            const SizedBox(height: 32),

            // Weekly Spending Trend
            SlideInAnimation(
              index: 1,
              child: _buildWeeklyTrendSection(
                context,
                weeklySpendingAsync,
                isDark,
                textPrimary,
                textSecondary,
                surface,
                signalBlue,
              ),
            ),

            const SizedBox(height: 32),

            // Category Breakdown
            SlideInAnimation(
              index: 2,
              child: _buildCategorySection(
                context,
                categorySpendingAsync,
                isDark,
                textPrimary,
                textSecondary,
                surface,
              ),
            ),

            const SizedBox(height: 32),

            // Insights Cards
            SlideInAnimation(
              index: 3,
              child: _buildInsightsCards(
                context,
                ref,
                isDark,
                textPrimary,
                textSecondary,
                surface,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRingSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        ref.read(preferencesServiceProvider).getMonthlyBudget(),
        ref.read(recurringRulesRepositoryProvider).getTotalMonthlyAmount(),
      ]),
      builder: (context, snapshot) {
        final budget = (snapshot.data?[0] as double?) ?? 30000.0;
        final fixed = (snapshot.data?[1] as double?) ?? 5000.0;

        final spentAsync = ref.watch(spentTodayProvider);
        final spent = spentAsync.asData?.value ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(LucideIcons.pieChart, color: textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Budget',
                    style: AppTypography.bodyM(
                      textSecondary,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Ring chart centered
              Center(
                child: SegmentedRingChart(
                  totalBudget: budget,
                  fixedExpenses: fixed,
                  variableSpent: spent * 30,
                ),
              ),
              const SizedBox(height: 24),
              // Legend below chart (full width)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Fixed', fixed, const Color(0xFF6B7280)),
                  _buildLegendItem(
                    'Variable',
                    spent * 30,
                    isDark
                        ? AppColors.signalBlueDark
                        : AppColors.signalBlueLight,
                  ),
                  _buildLegendItem(
                    'Left',
                    budget - fixed - (spent * 30),
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.caption(Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: AppTypography.bodyMTabular(
            Colors.grey.shade700,
          ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendSection(
    BuildContext context,
    AsyncValue<List<DailySpending>> weeklySpendingAsync,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
    Color signalBlue,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, color: textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Last 7 Days',
                style: AppTypography.bodyM(
                  textSecondary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          weeklySpendingAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: Text('No data yet')),
                );
              }

              final maxAmount = data.fold<double>(
                0,
                (max, d) => d.amount > max ? d.amount : max,
              );

              return SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final barHeight = maxAmount > 0
                        ? (day.amount / maxAmount * 80)
                        : 4.0;
                    final isToday = index == data.length - 1;

                    return _AnimatedBar(
                      index: index,
                      height: barHeight,
                      label: day.dayLabel,
                      isToday: isToday,
                      color: signalBlue,
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => const SizedBox(
              height: 120,
              child: Center(child: Text('Error loading data')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    AsyncValue<List<CategorySpending>> categorySpendingAsync,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layoutGrid, color: textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'By Category',
                style: AppTypography.bodyM(
                  textSecondary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          categorySpendingAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No spending data yet')),
                );
              }

              final maxAmount = data.fold<double>(
                0,
                (max, d) => d.amount > max ? d.amount : max,
              );

              final barData = data
                  .map(
                    (c) => CategoryBarData(
                      label: c.categoryName,
                      amount: c.amount,
                      color: CategoryIcons.getColor(c.categoryName, isDark),
                    ),
                  )
                  .toList();

              return HorizontalBarChart(data: barData, maxValue: maxAmount);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Center(child: Text('Error')),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCards(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.lightbulb, color: textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Smart Insights',
              style: AppTypography.bodyM(
                textSecondary,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: LucideIcons.trendingDown,
          title: 'Spending on track',
          subtitle: 'You\'re within your daily budget today',
          color: isDark
              ? AppColors.insightPositiveDark
              : AppColors.insightPositiveLight,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: LucideIcons.alertCircle,
          title: 'Food spending up',
          subtitle: 'You\'ve spent 15% more on food this week',
          color: isDark
              ? AppColors.insightWarningDark
              : AppColors.insightWarningLight,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyM(
                    isDark ? Colors.white : Colors.black87,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final int index;
  final double height;
  final String label;
  final bool isToday;
  final Color color;

  const _AnimatedBar({
    required this.index,
    required this.height,
    required this.label,
    required this.isToday,
    required this.color,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heightAnimation = Tween<double>(
      begin: 0,
      end: widget.height,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: _heightAnimation.value.clamp(4.0, 80.0),
              decoration: BoxDecoration(
                color: widget.isToday
                    ? widget.color
                    : widget.color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isToday ? FontWeight.w600 : FontWeight.w400,
                color: widget.isToday ? widget.color : Colors.grey.shade500,
              ),
            ),
          ],
        );
      },
    );
  }
}
