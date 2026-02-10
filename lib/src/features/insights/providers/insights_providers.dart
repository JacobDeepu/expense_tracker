import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/local/tables.dart';

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

/// Provider for category spending this month (reactive)
final categorySpendingProvider = StreamProvider<List<CategorySpending>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final lastOfMonth = DateTime(now.year, now.month + 1, 0);

  // Watch current month expenses
  final query = db.select(db.transactions)
    ..where((t) => t.date.isBetweenValues(firstOfMonth, lastOfMonth))
    ..where((t) => t.type.equals(TransactionType.expense.index));

  return query.watch().asyncMap((transactions) async {
    final categories = await db.select(db.categories).get();
    final categoryMap = {for (var c in categories) c.id: c.name};

    final Map<String, double> spending = {};
    for (final tx in transactions) {
      final name = categoryMap[tx.categoryId] ?? 'Other';
      spending[name] = (spending[name] ?? 0) + tx.amount;
    }

    final result =
        spending.entries
            .map((e) => CategorySpending(categoryName: e.key, amount: e.value))
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return result.take(5).toList();
  });
});

/// Provider for weekly spending trend (reactive)
final weeklySpendingProvider = StreamProvider<List<DailySpending>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  // Watch last 7 days of expenses
  final query = db.select(db.transactions)
    ..where(
      (t) =>
          t.date.isBetweenValues(weekAgo, today.add(const Duration(days: 1))),
    )
    ..where((t) => t.type.equals(TransactionType.expense.index));

  return query.watch().map((transactions) {
    // Initialize all 7 days to 0
    final Map<String, double> dailyTotals = {};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      dailyTotals[key] = 0;
    }

    // Accumulate transaction amounts by day
    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final key = DateFormat('yyyy-MM-dd').format(txDate);
      if (dailyTotals.containsKey(key)) {
        dailyTotals[key] = dailyTotals[key]! + tx.amount;
      }
    }

    // Convert to ordered list
    final result = <DailySpending>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      result.add(DailySpending(date: date, amount: dailyTotals[key] ?? 0));
    }

    return result;
  });
});
