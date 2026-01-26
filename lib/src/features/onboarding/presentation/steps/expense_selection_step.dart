import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../data/onboarding_data.dart';
import '../../data/recurring_rules_repository.dart';
import '../../widgets/swipe_card.dart';
import '../../widgets/add_recurring_expense_sheet.dart';

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

  // Mutable list of cards (core + custom added)
  late List<OnboardingCard> _cards;

  // Track edited amounts/frequencies per card index
  final Map<int, OnboardingCard> _editedCards = {};

  // Selected cards to save
  final List<OnboardingCard> _selectedCards = [];

  // Whether we've finished the core cards and are in "add custom" mode
  bool _showAddCustomPrompt = false;

  @override
  void initState() {
    super.initState();
    // Start with the 3 core cards
    _cards = List.from(coreOnboardingCards);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCardUpdate(int index, OnboardingCard updatedCard) {
    setState(() {
      _editedCards[index] = updatedCard;
      _cards[index] = updatedCard;
    });
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // Get the (potentially edited) card
    final card = _editedCards[previousIndex] ?? _cards[previousIndex];

    if (direction == CardSwiperDirection.right) {
      _selectedCards.add(card);
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    // Check if we've gone through all cards
    if (currentIndex == null) {
      setState(() {
        _showAddCustomPrompt = true;
      });
    }

    return true;
  }

  void _addCustomExpense(OnboardingCard card) {
    setState(() {
      // Add to selected directly (user explicitly created it)
      _selectedCards.add(card);
    });
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
                _showAddCustomPrompt
                    ? 'Add more\nexpenses?'
                    : 'What do you\npay for?',
                style: AppTypography.displayL(textColor).copyWith(height: 1.1),
              ),
              const SizedBox(height: 16),
              Text(
                _showAddCustomPrompt
                    ? 'Add your own recurring expenses'
                    : 'Swipe right to add, left to skip\nTap card to edit amount',
                style: AppTypography.bodyL(textSecondary),
              ),
            ],
          ),
        ),

        // Show either the card swiper or the add custom prompt
        Expanded(
          child: _showAddCustomPrompt
              ? _buildAddCustomView(textColor, textSecondary)
              : _buildCardSwiper(),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: _showAddCustomPrompt
              ? _buildCustomViewButtons(textSecondary)
              : _buildSwiperButtons(textSecondary),
        ),
      ],
    );
  }

  Widget _buildCardSwiper() {
    return CardSwiper(
      controller: _controller,
      cardsCount: _cards.length,
      onSwipe: _handleSwipe,
      isLoop: false,
      numberOfCardsDisplayed: _cards.length.clamp(1, 3),
      backCardOffset: const Offset(0, 30),
      padding: const EdgeInsets.all(24),
      cardBuilder:
          (
            context,
            index,
            horizontalThresholdPercentage,
            verticalThresholdPercentage,
          ) {
            return SwipeCard(
              card: _editedCards[index] ?? _cards[index],
              onCardUpdated: (updated) => _handleCardUpdate(index, updated),
            );
          },
    );
  }

  Widget _buildAddCustomView(Color textColor, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show count of selected expenses
          if (_selectedCards.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${_selectedCards.length}',
                    style: AppTypography.displayL(textColor),
                  ),
                  Text(
                    'expenses added',
                    style: AppTypography.bodyM(textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Add custom button
          OutlinedButton.icon(
            onPressed: () {
              showAddExpenseSheet(context, _addCustomExpense);
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Custom Expense',
              style: AppTypography.bodyL(Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiperButtons(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => _controller.swipe(CardSwiperDirection.left),
          icon: const Icon(Icons.close, size: 24, color: Colors.white70),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
          label: Text(
            'Skip',
            style: AppTypography.bodyL(textSecondary).copyWith(height: 1.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            minimumSize: const Size(100, 48),
            alignment: Alignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomViewButtons(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _finishStep,
          child: Text(
            _selectedCards.isEmpty ? 'Skip All' : 'Continue',
            style: AppTypography.bodyL(textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _finishStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Done',
            style: AppTypography.bodyL(
              Colors.black,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
