import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database.dart';
import '../../transactions/presentation/add_transaction_sheet.dart';
import '../providers/dashboard_providers.dart';

class RecurringPaymentsCard extends ConsumerWidget {
  const RecurringPaymentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final unpaidRulesAsync = ref.watch(unpaidRecurringRulesProvider);

    return unpaidRulesAsync.when(
      data: (rules) {
        if (rules.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceSecondaryDark
                : AppColors.surfacePrimaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendarClock,
                      size: 20,
                      color: signalBlue,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Upcoming Bills',
                      style: AppTypography.headingM(
                        textPrimary,
                      ).copyWith(fontSize: 18),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: signalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${rules.length}',
                        style: AppTypography.bodyM(
                          signalBlue,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: border, indent: 64),
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return _RecurringItemTile(
                    rule: rule,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    signalBlue: signalBlue,
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, s) => const SizedBox(),
    );
  }
}

class _RecurringItemTile extends StatelessWidget {
  final RecurringRule rule;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color signalBlue;

  const _RecurringItemTile({
    required this.rule,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.signalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              rule.isVariable ? LucideIcons.zap : LucideIcons.repeat,
              size: 20,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: AppTypography.bodyM(
                    textPrimary,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.dueDate != null
                      ? 'Due on day ${rule.dueDate}'
                      : 'Next payment',
                  style: AppTypography.caption(textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${rule.estimatedAmount.toStringAsFixed(0)}',
                style: AppTypography.bodyMTabular(
                  textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => AddTransactionSheet(
                      recurringRuleId: rule.id,
                      initialAmount: rule.estimatedAmount.toStringAsFixed(0),
                      initialMerchant: rule.name,
                      initialCategoryId: rule.categoryId,
                    ),
                  );
                },
                child: Text(
                  'Pay Now',
                  style: AppTypography.caption(
                    signalBlue,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
