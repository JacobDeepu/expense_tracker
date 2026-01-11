import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/preferences_service.dart';

class BudgetStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BudgetStep({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends ConsumerState<BudgetStep> {
  String _amount = '';
  final int _maxLength = 8;

  void _onKeyPress(String value) {
    if (_amount.length >= _maxLength) return;
    if (value == '.' && _amount.contains('.')) return;
    if (value == '0' && _amount.isEmpty) return;

    setState(() {
      _amount += value;
    });
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    if (_amount.isNotEmpty) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _saveAndContinue() async {
    if (_amount.isEmpty) return;

    final budget = double.tryParse(_amount) ?? 0.0;
    if (budget > 0) {
      await ref.read(preferencesServiceProvider).saveMonthlyBudget(budget);
      widget.onNext();
    }
  }

  String get _formattedAmount {
    if (_amount.isEmpty) return '0';
    final number = double.tryParse(_amount) ?? 0;
    return NumberFormat.decimalPattern('en_IN').format(number);
  }

  double get _dailyLimit {
    final monthly = double.tryParse(_amount) ?? 0;
    return monthly / 30; // Approximation
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
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: textColor),
              ),
              const Spacer(),
              Text(
                'BUDGET',
                style: AppTypography.captionUppercase(textSecondary),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance back button
            ],
          ),
        ),

        const Spacer(),

        // Display
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set your monthly goal',
              style: AppTypography.headingM(textColor),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹',
                  style: AppTypography.displayXL(
                    textColor,
                  ).copyWith(fontSize: 48, fontWeight: FontWeight.w300),
                ),
                Text(
                  _formattedAmount,
                  style: AppTypography.displayXL(
                    textColor,
                  ).copyWith(fontSize: 80, letterSpacing: -2, height: 1.0),
                ),
              ],
            ),
            if (_amount.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Daily Limit: ₹${NumberFormat.decimalPattern('en_IN').format(_dailyLimit.floor())}',
                  style: AppTypography.bodyL(textSecondary),
                ),
              ),
            ],
          ],
        ),

        const Spacer(),

        // Keypad
        Container(
          height: 320, // Fixed height for keypad area
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _buildKeypadRow(['1', '2', '3']),
              _buildKeypadRow(['4', '5', '6']),
              _buildKeypadRow(['7', '8', '9']),
              _buildKeypadRow(['.', '0', 'backspace']),
            ],
          ),
        ),

        // Continue Button
        Padding(
          padding: const EdgeInsets.fromLTRB(
            32,
            16,
            32,
            32,
          ), // Added bottom padding
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _amount.isNotEmpty ? _saveAndContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
                elevation: 0,
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue',
                style: AppTypography.headingS(
                  Colors.black,
                ).copyWith(height: 1.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: InkWell(
              onTap: () {
                if (key == 'backspace') {
                  _onBackspace();
                } else {
                  _onKeyPress(key);
                }
              },
              customBorder: const CircleBorder(),
              child: Center(
                child: key == 'backspace'
                    ? const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                        size: 28,
                      )
                    : Text(
                        key,
                        style: AppTypography.displayL(
                          Colors.white,
                        ).copyWith(fontSize: 32),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
