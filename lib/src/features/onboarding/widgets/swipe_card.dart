import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/onboarding_data.dart';

/// Individual swipe card widget with physical card aesthetic
class SwipeCard extends StatelessWidget {
  final OnboardingCard card;

  const SwipeCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Card uses light theme colors for physical card feel (cream/white)
    // regardless of app theme - intentional design choice
    final cardColor = isDark
        ? AppColors.surfaceSecondaryLight
        : AppColors.surfacePrimaryLight;
    final cardTextPrimary = AppColors.textPrimaryLight;
    final cardTextSecondary = AppColors.textSecondaryLight;

    return Container(
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

          // Estimated amount
          Text(
            card.formattedAmount,
            style: AppTypography.headingM(cardTextPrimary),
          ),
          const SizedBox(height: 8),

          // Description
          if (card.description != null)
            Text(
              card.description!,
              style: AppTypography.bodyM(cardTextSecondary),
            ),
        ],
      ),
    );
  }
}
