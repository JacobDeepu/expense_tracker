import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/onboarding_data.dart';
import '../widgets/swipe_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<OnboardingCard> _cards = sampleOnboardingCards;
  final List<OnboardingCard> _selectedCards = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // Right swipe = Add to recurring expenses
    if (direction == CardSwiperDirection.right) {
      _selectedCards.add(_cards[previousIndex]);
    }

    // If all cards swiped, navigate to reminder time screen
    if (currentIndex == null) {
      Future.microtask(() {
        if (mounted) {
          context.go(RouteNames.reminderTime);
        }
      });
    }

    return true;
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
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETUP',
                    style: AppTypography.captionUppercase(textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What do you pay for?',
                    style: AppTypography.displayL(textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Swipe right to add, left to skip',
                    style: AppTypography.bodyM(textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Card Swiper
            Expanded(
              child: CardSwiper(
                controller: _controller,
                cardsCount: _cards.length,
                onSwipe: _handleSwipe,
                isLoop: false,
                numberOfCardsDisplayed: 2,
                backCardOffset: const Offset(0, 20),
                padding: EdgeInsets.zero,
                duration: const Duration(milliseconds: 200),
                cardBuilder:
                    (
                      context,
                      index,
                      horizontalThresholdPercentage,
                      verticalThresholdPercentage,
                    ) {
                      return SwipeCard(card: _cards[index]);
                    },
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_back, size: 20, color: textSecondary),
                      const SizedBox(width: 8),
                      Text('Skip', style: AppTypography.bodyM(textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Add', style: AppTypography.bodyM(textSecondary)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
