import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/onboarding_data.dart';

/// Individual swipe card widget with physical card aesthetic
/// Supports inline editing of amount and frequency
class SwipeCard extends StatelessWidget {
  final OnboardingCard card;
  final ValueChanged<OnboardingCard>? onCardUpdated;

  const SwipeCard({super.key, required this.card, this.onCardUpdated});

  void _showEditDialog(BuildContext context) {
    final amountController = TextEditingController(
      text: card.estimatedAmount.toStringAsFixed(0),
    );
    ExpenseFrequency selectedFrequency = card.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final surface = isDark
              ? AppColors.surfaceSecondaryDark
              : AppColors.surfaceSecondaryLight;
          final textPrimary = isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight;
          final textSecondary = isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight;
          final accent = isDark
              ? AppColors.signalBlueDark
              : AppColors.signalBlueLight;

          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit ${card.name}',
              style: AppTypography.headingS(textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount field
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: AppTypography.headingM(textPrimary),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.headingM(textPrimary),
                    labelText: 'Amount',
                    labelStyle: AppTypography.bodyM(textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Frequency selector
                Text('Frequency', style: AppTypography.bodyM(textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ExpenseFrequency.values.map((freq) {
                    final isSelected = freq == selectedFrequency;
                    return ChoiceChip(
                      label: Text(freq.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedFrequency = freq);
                        }
                      },
                      selectedColor: accent.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodyM(
                        isSelected ? accent : textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? accent
                              : textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyM(textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    final updated = card.copyWith(
                      estimatedAmount: amount,
                      frequency: selectedFrequency,
                    );
                    onCardUpdated?.call(updated);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  'Save',
                  style: AppTypography.bodyM(
                    accent,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Card uses light theme colors for physical card feel (cream/white)
    // regardless of app theme - intentional design choice
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.surfaceSecondaryLight
        : AppColors.surfacePrimaryLight;
    final cardTextPrimary = AppColors.textPrimaryLight;
    final cardTextSecondary = AppColors.textSecondaryLight;
    final accent = AppColors.signalBlueLight;

    return GestureDetector(
      onTap: onCardUpdated != null ? () => _showEditDialog(context) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category label
            Text(
              card.category.toUpperCase(),
              style: AppTypography.captionUppercase(cardTextSecondary),
            ),
            const SizedBox(height: 16),

            // Card name
            Text(card.name, style: AppTypography.displayL(cardTextPrimary)),
            const SizedBox(height: 24),

            // Estimated amount with frequency
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  card.formattedAmount,
                  style: AppTypography.headingM(cardTextPrimary),
                ),
                const SizedBox(width: 4),
                Text(
                  card.frequency.suffix,
                  style: AppTypography.bodyM(cardTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (card.description != null)
              Text(
                card.description!,
                style: AppTypography.bodyM(cardTextSecondary),
              ),

            const SizedBox(height: 16),

            // Edit hint
            if (onCardUpdated != null)
              Row(
                children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text('Tap to edit', style: AppTypography.caption(accent)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
