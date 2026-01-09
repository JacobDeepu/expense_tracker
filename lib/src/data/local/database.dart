import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Transactions, Categories, NotificationPatterns, RecurringRules],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'expense_tracker.db');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultCategories();
      },
    );
  }

  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        iconKey: 'restaurant',
        colorHex: 'F59E0B',
      ),
      CategoriesCompanion.insert(
        name: 'Transport',
        iconKey: 'directions_car',
        colorHex: '3B82F6',
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        iconKey: 'shopping_bag',
        colorHex: 'EC4899',
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        iconKey: 'movie',
        colorHex: '8B5CF6',
      ),
      CategoriesCompanion.insert(
        name: 'Bills & Utilities',
        iconKey: 'receipt',
        colorHex: '10B981',
      ),
      CategoriesCompanion.insert(
        name: 'Health',
        iconKey: 'local_hospital',
        colorHex: 'EF4444',
      ),
      CategoriesCompanion.insert(
        name: 'Other',
        iconKey: 'category',
        colorHex: '6B7280',
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }
}
