import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../widgets/top_categories_card.dart';

/// Provider for top spending categories (top 3)
final topCategoriesProvider = FutureProvider<List<CategoryData>>((ref) async {
  final db = ref.watch(databaseProvider);

  // Get all transactions
  final transactions = await db.select(db.transactions).get();

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
      final percentage = grandTotal > 0 ? (entry.value / grandTotal) * 100 : 0;
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
