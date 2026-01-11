import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import 'steps/welcome_step.dart';
import 'steps/reminder_step.dart';
import 'steps/expense_selection_step.dart';
import 'steps/budget_step.dart';
import 'steps/summary_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();

  // Default gradient (Welcome Screen)
  LinearGradient _currentGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black, Colors.black],
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _updateGradient(LinearGradient newGradient) {
    setState(() {
      _currentGradient = newGradient;
    });
  }

  void _finishOnboarding() {
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: _currentGradient),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable swipe to change page, enforce button flow
            children: [
              // 1. Welcome
              WelcomeStep(onNext: _nextPage),

              // 2. Reminder Setup (Controls Gradient)
              ReminderStep(
                onNext: _nextPage,
                onBack: _previousPage,
                onGradientChanged: _updateGradient,
              ),

              // 3. Expense Selection
              ExpenseSelectionStep(onNext: _nextPage, onBack: _previousPage),

              // 4. Budget Setup
              BudgetStep(onNext: _nextPage, onBack: _previousPage),

              // 5. Summary
              SummaryStep(onFinish: _finishOnboarding, onBack: _previousPage),
            ],
          ),
        ),
      ),
    );
  }
}
