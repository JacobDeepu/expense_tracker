import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import 'onboarding_data.dart';

class RecurringRulesRepository {
  final AppDatabase _db;

  RecurringRulesRepository(this._db);

  /// Bulk insert recurring rules from onboarding cards
  Future<void> addRules(List<OnboardingCard> cards) async {
    final categories = await _db.select(_db.categories).get();
    final categoryMap = {for (var c in categories) c.name: c.id};

    await _db.batch((batch) {
      for (final card in cards) {
        int? categoryId = categoryMap[card.category];

        // Fallback to 'Other' category
        if (categoryId == null) {
          final otherCat = categories.cast<Category?>().firstWhere(
            (c) => c?.name == 'Other',
            orElse: () => null,
          );
          categoryId = otherCat?.id;
        }

        batch.insert(
          _db.recurringRules,
          RecurringRulesCompanion(
            name: Value(card.name),
            estimatedAmount: Value(card.estimatedAmount),
            frequencyDays: Value(card.frequency.days),
            categoryId: Value(categoryId),
          ),
        );
      }
    });
  }

  /// Get all recurring rules
  Future<List<RecurringRule>> getAllRules() {
    return _db.select(_db.recurringRules).get();
  }

  /// Watch all recurring rules (reactive)
  Stream<List<RecurringRule>> watchAllRules() {
    return _db.select(_db.recurringRules).watch();
  }

  /// Add a single recurring rule
  Future<int> addSingleRule({
    required String name,
    required double amount,
    required int frequencyDays,
    int? categoryId,
  }) {
    return _db
        .into(_db.recurringRules)
        .insert(
          RecurringRulesCompanion(
            name: Value(name),
            estimatedAmount: Value(amount),
            frequencyDays: Value(frequencyDays),
            categoryId: Value(categoryId),
          ),
        );
  }

  /// Update an existing rule
  Future<bool> updateRule({
    required int id,
    String? name,
    double? amount,
    int? frequencyDays,
    int? categoryId,
  }) {
    return (_db.update(_db.recurringRules)..where((r) => r.id.equals(id)))
        .write(
          RecurringRulesCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            estimatedAmount: amount != null
                ? Value(amount)
                : const Value.absent(),
            frequencyDays: frequencyDays != null
                ? Value(frequencyDays)
                : const Value.absent(),
            categoryId: categoryId != null
                ? Value(categoryId)
                : const Value.absent(),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Delete a recurring rule
  Future<bool> deleteRule(int id) {
    return (_db.delete(
      _db.recurringRules,
    )..where((r) => r.id.equals(id))).go().then((rows) => rows > 0);
  }

  /// Get total monthly recurring expenses (normalized to monthly)
  Future<double> getTotalMonthlyAmount() async {
    final rules = await getAllRules();
    return rules.fold<double>(0.0, (sum, rule) {
      // Normalize to monthly: (amount / frequencyDays) * 30
      final monthly = (rule.estimatedAmount / rule.frequencyDays) * 30;
      return sum + monthly;
    });
  }
}

final recurringRulesRepositoryProvider = Provider<RecurringRulesRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return RecurringRulesRepository(db);
});

/// Provider for watching all recurring rules
final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(recurringRulesRepositoryProvider).watchAllRules();
});
