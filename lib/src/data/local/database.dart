import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    NotificationPatterns,
    RecurringRules,
    TransactionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

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
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add columns to RecurringRules in Version 2
          await m.addColumn(recurringRules, recurringRules.dueDate);
          await m.addColumn(recurringRules, recurringRules.isVariable);
          await m.addColumn(recurringRules, recurringRules.active);
        }
        if (from < 3) {
          // Add column to Transactions in Version 3
          await m.addColumn(transactions, transactions.recurringRuleId);
        }
        if (from < 4) {
          // Add TransactionItems table in Version 4
          await m.createTable(transactionItems);
        }
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
        name: 'Cash Spend',
        iconKey: 'payments',
        colorHex: '10B981',
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
