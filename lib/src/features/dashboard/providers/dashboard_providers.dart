import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../../data/local/database.dart';
import '../../onboarding/data/recurring_rules_repository.dart';
import '../../../core/services/preferences_service.dart';

/// Provider for Monthly Budget Goal
final monthlyBudgetProvider = FutureProvider<double>((ref) async {
  final prefs = ref.watch(preferencesServiceProvider);
  return await prefs.getMonthlyBudget() ?? 0.0;
});

/// Provider for total monthly income
final monthlyIncomeProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchMonthlyIncome();
});

/// Provider for total monthly expenses
final monthlyExpensesProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchMonthlyExpenses();
});

/// Provider for spent today
final spentTodayProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchSpentToday();
});

/// Provider for active recurring expenses total (reactive)
final activeRecurringTotalProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(recurringRulesRepositoryProvider);
  return repository.watchTotalMonthlyAmount();
});

/// Provider for "Safe Daily Spend"
/// Formula: (Budget + Income - Committed Recurring - Spent Variable) / Days Remaining
final safeDailySpendProvider = Provider<AsyncValue<double>>((ref) {
  final budgetAsync = ref.watch(monthlyBudgetProvider);
  final incomeAsync = ref.watch(monthlyIncomeProvider);
  final expensesAsync = ref.watch(monthlyExpensesProvider);
  final recurringAsync = ref.watch(activeRecurringTotalProvider);

  if (budgetAsync.isLoading ||
      incomeAsync.isLoading ||
      expensesAsync.isLoading ||
      recurringAsync.isLoading) {
    return const AsyncLoading();
  }

  final budget = budgetAsync.asData?.value ?? 0.0;
  final income = incomeAsync.asData?.value ?? 0.0;
  final expenses = expensesAsync.asData?.value ?? 0.0;
  final recurring = recurringAsync.asData?.value ?? 0.0;

  // Safe to Spend = (Total Pot - Recurring Committed - Spent So Far)
  final available = (budget + income) - recurring - expenses;

  // Calculate days remaining in month (inclusive of today)
  final now = DateTime.now();
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = (lastDayOfMonth - now.day + 1).clamp(1, 31);

  return AsyncData(available / daysRemaining);
});

/// Provider for budget usage percentage (for the ring chart)
final budgetUsageProvider = Provider<AsyncValue<double>>((ref) {
  final budgetAsync = ref.watch(monthlyBudgetProvider);
  final incomeAsync = ref.watch(monthlyIncomeProvider);
  final expensesAsync = ref.watch(monthlyExpensesProvider);

  if (budgetAsync.isLoading ||
      incomeAsync.isLoading ||
      expensesAsync.isLoading) {
    return const AsyncLoading();
  }

  final totalBudget =
      (budgetAsync.asData?.value ?? 0.0) + (incomeAsync.asData?.value ?? 0.0);
  final spent = expensesAsync.asData?.value ?? 0.0;

  if (totalBudget <= 0) return const AsyncData(0.0);

  return AsyncData((spent / totalBudget).clamp(0.0, 1.0));
});

/// Provider for recent transactions (last 20)
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchRecentTransactions();
});

/// Provider for paid recurring rule IDs this month (reactive)
final paidRecurringIdsProvider = StreamProvider<Set<int>>((ref) {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);
  return transactionsRepo.watchPaidRecurringRuleIds(DateTime.now());
});

/// Provider for unpaid recurring rules this month
/// Reacts to BOTH rule changes AND new transactions (bill payments)
final unpaidRecurringRulesProvider = Provider<AsyncValue<List<RecurringRule>>>((
  ref,
) {
  final rulesAsync = ref.watch(recurringRulesProvider);
  final paidIdsAsync = ref.watch(paidRecurringIdsProvider);

  if (rulesAsync.isLoading || paidIdsAsync.isLoading) {
    return const AsyncLoading();
  }

  if (rulesAsync.hasError) {
    return AsyncError(rulesAsync.error!, StackTrace.current);
  }
  if (paidIdsAsync.hasError) {
    return AsyncError(paidIdsAsync.error!, StackTrace.current);
  }

  final rules = rulesAsync.asData?.value ?? [];
  final paidIds = paidIdsAsync.asData?.value ?? {};

  final unpaid = rules
      .where((r) => r.active && !paidIds.contains(r.id))
      .toList();
  return AsyncData(unpaid);
});
