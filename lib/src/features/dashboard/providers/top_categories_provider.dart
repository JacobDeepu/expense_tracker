import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/local/tables.dart';
import '../widgets/top_categories_card.dart';

/// Provider for top spending categories (top 3, current month, reactive)
final topCategoriesProvider = StreamProvider<List<CategoryData>>((ref) {
  final db = ref.watch(databaseProvider);

  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final lastOfMonth = DateTime(now.year, now.month + 1, 0);

  // Watch current month expenses only
  final query = db.select(db.transactions)
    ..where((t) => t.date.isBetweenValues(firstOfMonth, lastOfMonth))
    ..where((t) => t.type.equals(TransactionType.expense.index));

  return query.watch().asyncMap((transactions) async {
    if (transactions.isEmpty) return <CategoryData>[];

    // Group by category and calculate totals
    final Map<int, double> categoryTotals = {};
    double grandTotal = 0;

    for (final transaction in transactions) {
      categoryTotals[transaction.categoryId] =
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
      grandTotal += transaction.amount;
    }

    // Get category details and sort by amount
    final List<CategoryData> categoryDataList = [];

    for (final entry in categoryTotals.entries) {
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(entry.key))).getSingleOrNull();

      if (category != null) {
        final percentage = grandTotal > 0
            ? (entry.value / grandTotal) * 100
            : 0;
        categoryDataList.add(
          CategoryData(
            name: category.name,
            amount: entry.value,
            percentage: percentage.toDouble(),
          ),
        );
      }
    }

    // Sort by amount descending and take top 3
    categoryDataList.sort((a, b) => b.amount.compareTo(a.amount));
    return categoryDataList.take(3).toList();
  });
});
