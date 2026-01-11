import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/database_provider.dart';

/// Category spending data
class CategorySpending {
  final String categoryName;
  final double amount;

  const CategorySpending({required this.categoryName, required this.amount});
}

/// Daily spending for trend chart
class DailySpending {
  final DateTime date;
  final double amount;
  final String dayLabel;

  DailySpending({required this.date, required this.amount})
    : dayLabel = DateFormat('E').format(date).substring(0, 2);
}

/// Provider for category spending this month
final categorySpendingProvider = FutureProvider<List<CategorySpending>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);

  // Get all transactions from current month
  final transactions = await db.select(db.transactions).get();

  // Get all categories
  final categories = await db.select(db.categories).get();
  final categoryMap = {for (var c in categories) c.id: c.name};

  // Filter to current month and group by category
  final now = DateTime.now();
  final Map<String, double> spending = {};

  for (final tx in transactions) {
    if (tx.date.year == now.year && tx.date.month == now.month) {
      final name = categoryMap[tx.categoryId] ?? 'Other';
      spending[name] = (spending[name] ?? 0) + tx.amount;
    }
  }

  // Sort by amount descending
  final result =
      spending.entries
          .map((e) => CategorySpending(categoryName: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

  return result.take(5).toList(); // Top 5
});

/// Provider for weekly spending trend
final weeklySpendingProvider = FutureProvider<List<DailySpending>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  // Get all transactions from last 7 days
  final transactions = await db.select(db.transactions).get();

  // Group by day
  final Map<String, double> dailyTotals = {};

  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final key = DateFormat('yyyy-MM-dd').format(date);
    dailyTotals[key] = 0;
  }

  for (final tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (txDate.isAfter(weekAgo.subtract(const Duration(days: 1))) &&
        txDate.isBefore(today.add(const Duration(days: 1)))) {
      final key = DateFormat('yyyy-MM-dd').format(txDate);
      if (dailyTotals.containsKey(key)) {
        dailyTotals[key] = dailyTotals[key]! + tx.amount;
      }
    }
  }

  // Convert to list
  final result = <DailySpending>[];
  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final key = DateFormat('yyyy-MM-dd').format(date);
    result.add(DailySpending(date: date, amount: dailyTotals[key] ?? 0));
  }

  return result;
});
