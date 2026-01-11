import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import 'onboarding_data.dart';

class RecurringRulesRepository {
  final AppDatabase _db;

  RecurringRulesRepository(this._db);

  /// Bulk insert recurring rules from onboarding cards
  Future<void> addRules(List<OnboardingCard> cards) async {
    // 1. Fetch all categories to map names to IDs
    final categories = await _db.select(_db.categories).get();
    final categoryMap = {for (var c in categories) c.name: c.id};

    // 2. Prepare batch insert
    await _db.batch((batch) {
      for (final card in cards) {
        // Find matching category ID (fuzzy match or default)
        // For MVP, we assume exact match or 'Other'
        int? categoryId = categoryMap[card.category];
        
        // If not found, try to find 'Other'
        if (categoryId == null) {
          final otherCat = categories.cast<Category?>().firstWhere(
              (c) => c?.name == 'Other',
              orElse: () => null);
          categoryId = otherCat?.id;
        }

        batch.insert(
          _db.recurringRules,
          RecurringRulesCompanion(
            name: Value(card.name),
            estimatedAmount: Value(card.estimatedAmount),
            frequencyDays: const Value(30), // Default monthly
            categoryId: Value(categoryId),
            // dayOfMonth is null (flexible)
          ),
        );
      }
    });
  }

  /// Get total monthly recurring expenses
  Future<double> getTotalMonthlyAmount() async {
    final result = await _db.select(_db.recurringRules).get();
    return result.fold(0.0, (sum, rule) => sum + rule.estimatedAmount);
  }
}

final recurringRulesRepositoryProvider = Provider<RecurringRulesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringRulesRepository(db);
});
