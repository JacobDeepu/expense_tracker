import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/route_names.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';

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
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Watch providers
    final dailyLimit = ref.watch(dailyLimitProvider);
    final budgetUsage = ref.watch(budgetUsageProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              // Header Section
              Text(
                'SAFE TO SPEND',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${dailyLimit.toStringAsFixed(0)}',
                style: AppTypography.displayXL(textPrimary),
              ),
              const SizedBox(height: 16),
              Text('Today\'s limit', style: AppTypography.bodyM(textSecondary)),
              const SizedBox(height: 32),

              // Budget Usage Progress Bar (1px height, subtle)
              Container(
                height: 1,
                width: double.infinity,
                decoration: BoxDecoration(color: border),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: budgetUsage,
                  child: Container(color: signalBlue),
                ),
              ),
              const SizedBox(height: 48),

              // Recent Transactions Section
              Text(
                'RECENT',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const SizedBox(height: 24),

              // Transaction List
              Expanded(
                child: ListView.builder(
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = recentTransactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Merchant name (left-aligned)
                          Text(
                            transaction.merchantName,
                            style: AppTypography.bodyM(textPrimary),
                          ),
                          // Amount (right-aligned, monospace)
                          Text(
                            '-${transaction.formattedAmount}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Add Expense Button
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(RouteNames.addTransaction);
                    },
                    child: const Text('Add Expense'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open transaction list
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: signalBlue, width: 1),
        ),
        child: Icon(Icons.list_rounded, color: signalBlue),
      ),
    );
  }
}
