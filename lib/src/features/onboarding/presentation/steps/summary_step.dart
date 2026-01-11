import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/preferences_service.dart';

class SummaryStep extends ConsumerWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const SummaryStep({super.key, required this.onFinish, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: textColor),
              ),
              const Spacer(),
            ],
          ),
        ),

        const Spacer(),

        // Success Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),

        const SizedBox(height: 32),

        Text('All Set!', style: AppTypography.displayL(textColor)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Your preferences have been saved. You are ready to start tracking.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyL(textSecondary),
          ),
        ),

        const Spacer(),

        // Finish Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await ref
                    .read(preferencesServiceProvider)
                    .setOnboardingComplete();
                onFinish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Go to Dashboard',
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
}
