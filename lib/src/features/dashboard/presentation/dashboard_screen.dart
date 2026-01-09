import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              Text(
                'SAFE TO SPEND',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const SizedBox(height: 8),
              Text('₹1,240', style: AppTypography.displayXL(textPrimary)),
              const SizedBox(height: 16),
              Text('Today\'s limit', style: AppTypography.bodyM(textSecondary)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Open quick add transaction
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
