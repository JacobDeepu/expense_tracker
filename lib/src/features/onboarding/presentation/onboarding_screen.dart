import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/onboarding_data.dart';
import '../data/recurring_rules_repository.dart';
import '../widgets/swipe_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<OnboardingCard> _cards = sampleOnboardingCards;
  final List<OnboardingCard> _selectedCards = [];
  bool _isSaving = false;

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

    // If all cards swiped (currentIndex is null), save and navigate
    if (currentIndex == null) {
      _finishOnboarding();
    }

    return true;
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Save selected rules to DB
      await ref.read(recurringRulesRepositoryProvider).addRules(_selectedCards);

      if (mounted) {
        context.go(RouteNames.reminderTime);
      }
    } catch (e) {
      // Handle error (log it)
      debugPrint('Error saving recurring rules: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setup: $e')),
        );
        // Navigate anyway for MVP continuity? Or stay?
        // Let's stay so they can retry or skip.
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

    if (_isSaving) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

            // Instructions / Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _controller.swipe(CardSwiperDirection.left),
                    icon: Icon(Icons.close, size: 20, color: textSecondary),
                    label:
                        Text('Skip', style: AppTypography.bodyM(textSecondary)),
                  ),
                  TextButton.icon(
                    onPressed: () => _controller.swipe(CardSwiperDirection.right),
                    label:
                        Text('Add', style: AppTypography.bodyM(textSecondary)),
                    icon: Icon(
                      Icons.check,
                      size: 20,
                      color: isDark ? Colors.greenAccent : Colors.green,
                    ),
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
