import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../data/onboarding_data.dart';
import '../../data/recurring_rules_repository.dart';
import '../../widgets/swipe_card.dart';

class ExpenseSelectionStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ExpenseSelectionStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<ExpenseSelectionStep> createState() =>
      _ExpenseSelectionStepState();
}

class _ExpenseSelectionStepState extends ConsumerState<ExpenseSelectionStep> {
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
    if (direction == CardSwiperDirection.right) {
      _selectedCards.add(_cards[previousIndex]);
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    if (currentIndex == null) {
      _finishStep();
    }

    return true;
  }

  Future<void> _finishStep() async {
    try {
      if (_selectedCards.isNotEmpty) {
        await ref
            .read(recurringRulesRepositoryProvider)
            .addRules(_selectedCards);
      }
    } catch (e) {
      debugPrint('Error saving recurring rules: $e');
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    // Determine text colors based on background (assuming dark background for now or passed down)
    // Since we can't easily read parent gradient brightness here without more complex state logic,
    // we default to white/light text as the gradients are mostly saturated/dark.
    const textColor = Colors.white;
    const textSecondary = Colors.white70;

    return Column(
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETUP',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'What do you\npay for?',
                style: AppTypography.displayL(textColor).copyWith(height: 1.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Swipe right to add, left to skip',
                style: AppTypography.bodyL(textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: _cards.length,
            onSwipe: _handleSwipe,
            isLoop: false,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, 30),
            padding: const EdgeInsets.all(24),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
                icon: const Icon(Icons.close, size: 24, color: textSecondary),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                ),
                label: Text(
                  'Skip',
                  style: AppTypography.bodyL(
                    textSecondary,
                  ).copyWith(height: 1.0),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _controller.swipe(CardSwiperDirection.right),
                icon: const Icon(Icons.check, size: 24),
                label: Text(
                  'Add',
                  style: AppTypography.bodyL(
                    Colors.black,
                  ).copyWith(fontWeight: FontWeight.w600, height: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ), // Add back horizontal padding for pill shape
                  minimumSize: const Size(100, 48), // Ensure touch target
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
