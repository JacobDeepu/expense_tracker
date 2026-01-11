import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/widgets/expandable_fab.dart';
import '../providers/dashboard_providers.dart';
import '../providers/top_categories_provider.dart';
import '../widgets/top_categories_card.dart';
import '../../transactions/presentation/widgets/edit_transaction_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    final signalRed = isDark
        ? AppColors.signalRedDark
        : AppColors.signalRedLight;
    final signalGreen = isDark
        ? AppColors.insightPositiveDark
        : AppColors.insightPositiveLight;

    // Watch providers
    final dailyLimitAsync = ref.watch(dailyLimitProvider);
    final budgetUsageAsync = ref.watch(budgetUsageProvider);
    final spentTodayAsync = ref.watch(spentTodayProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final topCategoriesAsync = ref.watch(topCategoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Clean, no duplicate settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_getGreeting()}',
                        style: AppTypography.bodyM(textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your finances',
                        style: AppTypography.headingM(textPrimary),
                      ),
                    ],
                  ),
                  // User avatar or brand mark (optional placeholder)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: signalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '₹',
                        style: AppTypography.headingM(signalBlue),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Main Balance Card
              dailyLimitAsync.when(
                data: (limit) {
                  final isPositive = limit >= 0;
                  final accentColor = isPositive ? signalGreen : signalRed;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPositive
                                  ? LucideIcons.trendingUp
                                  : LucideIcons.trendingDown,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPositive ? 'Available Today' : 'Over Budget',
                              style: AppTypography.bodyM(
                                Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${limit.abs().toStringAsFixed(0)}',
                          style: AppTypography.displayXLTabular(
                            Colors.white,
                          ).copyWith(fontSize: 44),
                        ),
                        const SizedBox(height: 16),
                        // Progress indicator
                        budgetUsageAsync.when(
                          data: (usage) {
                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: usage.clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.25,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    spentTodayAsync.when(
                                      data: (spent) => Text(
                                        '₹${spent.toStringAsFixed(0)} spent',
                                        style: AppTypography.caption(
                                          Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      loading: () => const SizedBox(),
                                      error: (e, s) => const SizedBox(),
                                    ),
                                    Text(
                                      '${(usage * 100).toInt()}% used',
                                      style: AppTypography.caption(
                                        Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (e, s) => const SizedBox(),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 180),
                error: (e, s) => const SizedBox(height: 180),
              ),

              const SizedBox(height: 16),

              // Top Categories
              topCategoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) return const SizedBox();
                  return TopCategoriesCard(
                    categories: categories,
                    onSeeMore: () => context.push(RouteNames.insights),
                  );
                },
                loading: () => const SizedBox(height: 180),
                error: (e, s) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppTypography.headingM(
                      textPrimary,
                    ).copyWith(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () => context.push(RouteNames.transactions),
                    child: Text(
                      'See all',
                      style: AppTypography.bodyM(signalBlue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              recentTransactions.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceSecondaryDark
                            : AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              size: 40,
                              color: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions yet',
                              style: AppTypography.bodyM(textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceSecondaryDark
                          : AppColors.surfacePrimaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: transactions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final transaction = entry.value;
                        final categoryIcon = CategoryIcons.getIcon('other');
                        final categoryColor = CategoryIcons.getColor(
                          'other',
                          isDark,
                        );

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => EditTransactionSheet(
                                    transaction: transaction,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.vertical(
                                top: index == 0
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottom: index == transactions.length - 1
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        categoryIcon,
                                        size: 20,
                                        color: categoryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.merchantName,
                                            style:
                                                AppTypography.bodyM(
                                                  textPrimary,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Expense',
                                            style: AppTypography.caption(
                                              textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-₹${transaction.amount.toStringAsFixed(0)}',
                                      style: AppTypography.bodyMTabular(
                                        textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < transactions.length - 1)
                              Divider(
                                height: 1,
                                indent: 74,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ExpandableFab(
        onAddPressed: () => context.push(RouteNames.addTransaction),
        onActivityPressed: () => context.push(RouteNames.transactions),
        onInsightsPressed: () => context.push(RouteNames.insights),
        onSettingsPressed: () => context.push(RouteNames.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
