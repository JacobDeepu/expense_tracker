import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/preferences_service.dart';

class BudgetSetupScreen extends ConsumerStatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  ConsumerState<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends ConsumerState<BudgetSetupScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    // Save budget to preferences
    await ref.read(preferencesServiceProvider).saveMonthlyBudget(amount);

    if (mounted) {
      context.go(RouteNames.reminderTime);
    }
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Text(
                'BUDGET',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'What is your monthly budget?',
                style: AppTypography.displayL(textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Used to calculate your daily safe limit',
                style: AppTypography.bodyM(textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),

              // Amount Input
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: AppTypography.displayXL(textPrimary)
                    .copyWith(fontSize: 64, letterSpacing: -1),
                decoration: InputDecoration(
                  hintText: '₹0',
                  hintStyle: AppTypography.displayXL(textSecondary)
                      .copyWith(fontSize: 64, letterSpacing: -1),
                  border: InputBorder.none,
                  prefixText: '₹',
                  prefixStyle: AppTypography.displayXL(textPrimary)
                      .copyWith(fontSize: 64, letterSpacing: -1),
                ),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
