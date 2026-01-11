import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HELLO',
                style: AppTypography.captionUppercase(Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to\nYour Money.',
                style: AppTypography.displayL(
                  Colors.white,
                ).copyWith(height: 1.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s get you set up in less than a minute.',
                style: AppTypography.bodyL(Colors.white70),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Get Started Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                fixedSize: const Size.fromHeight(56), // Enforce strict height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Get Started',
                style: AppTypography.headingS(
                  Colors.black,
                ).copyWith(height: 1.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
