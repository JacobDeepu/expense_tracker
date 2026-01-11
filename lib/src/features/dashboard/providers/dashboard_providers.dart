import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../../data/local/database.dart';
import '../../onboarding/data/recurring_rules_repository.dart';
import '../../../core/services/preferences_service.dart';

// REPLACED: MockDataService with Real Repository

/// Provider for Daily Base Budget (Fixed per day)
/// Formula: (Monthly Budget - Recurring Expenses) / 30
final dailyBaseBudgetProvider = FutureProvider<double>((ref) async {
  final prefs = ref.watch(preferencesServiceProvider);
  final monthlyBudget = await prefs.getMonthlyBudget() ?? 0.0;
  
  final recurringRepo = ref.watch(recurringRulesRepositoryProvider);
  final recurringTotal = await recurringRepo.getTotalMonthlyAmount();

  final disposableIncome = monthlyBudget - recurringTotal;
  // If negative disposable income, default to 0
  if (disposableIncome <= 0) return 0.0;

  return disposableIncome / 30; // Simple average for MVP
});

/// Provider for spent today
final spentTodayProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchSpentToday();
});

/// Provider for "Safe to Spend" (Remaining Today)
/// Formula: Daily Base Budget - Spent Today
final dailyLimitProvider = Provider<AsyncValue<double>>((ref) {
  final baseBudgetAsync = ref.watch(dailyBaseBudgetProvider);
  final spentTodayAsync = ref.watch(spentTodayProvider);

  if (baseBudgetAsync.isLoading || spentTodayAsync.isLoading) {
    return const AsyncLoading();
  }

  final baseBudget = baseBudgetAsync.asData?.value ?? 0.0;
  final spentToday = spentTodayAsync.asData?.value ?? 0.0;

  return AsyncData(baseBudget - spentToday);
});

/// Provider for budget usage percentage (0.0 to 1.0)
final budgetUsageProvider = Provider<AsyncValue<double>>((ref) {
  final baseBudgetAsync = ref.watch(dailyBaseBudgetProvider);
  final spentTodayAsync = ref.watch(spentTodayProvider);

  if (baseBudgetAsync.isLoading || spentTodayAsync.isLoading) {
    return const AsyncLoading();
  }

  final baseBudget = baseBudgetAsync.asData?.value ?? 1.0; // Avoid div by zero
  final spentToday = spentTodayAsync.asData?.value ?? 0.0;

  if (baseBudget == 0) return const AsyncData(1.0); // 100% used if no budget

  return AsyncData((spentToday / baseBudget).clamp(0.0, 1.0));
});

/// Provider for recent transactions (last 20)
// This connects to the real Drift Database via Repository
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchRecentTransactions();
});