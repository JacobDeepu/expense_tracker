import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data_service.dart';

/// Provider for the mock data service singleton
final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService();
});

/// Provider for monthly budget
final monthlyBudgetProvider = Provider<double>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getMonthlyBudget();
});

/// Provider for monthly expenses
final monthlyExpensesProvider = Provider<double>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getMonthlyExpenses();
});

/// Provider for daily limit (Safe to Spend)
final dailyLimitProvider = Provider<double>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getDailyLimit();
});

/// Provider for budget usage percentage (0.0 to 1.0)
final budgetUsageProvider = Provider<double>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getBudgetUsage();
});

/// Provider for recent transactions (last 5)
final recentTransactionsProvider = Provider<List<MockTransaction>>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  final allTransactions = service.getRecentTransactions();
  return allTransactions.take(5).toList();
});

/// Provider for all transactions
final allTransactionsProvider = Provider<List<MockTransaction>>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getRecentTransactions();
});

/// Provider for recurring rules
final recurringRulesProvider = Provider<List<MockRecurringRule>>((ref) {
  final service = ref.watch(mockDataServiceProvider);
  return service.getRecurringRules();
});
