import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import '../../../data/local/database_provider.dart';

class TransactionsRepository {
  final AppDatabase _db;

  TransactionsRepository(this._db);

  Future<int> addTransaction({
    required double amount,
    required String merchantName,
    required DateTime date,
    required TransactionSource source,
    required TransactionType type,
    String? rawText,
    int? categoryId,
  }) {
    // Default to 'Other' (ID 7) if no category provided
    const int defaultCategoryId = 7;

    return _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion(
            amount: Value(amount),
            merchantName: Value(merchantName),
            date: Value(date),
            source: Value(source),
            type: Value(type),
            rawText: Value(rawText),
            categoryId: Value(categoryId ?? defaultCategoryId),
          ),
        );
  }

  Stream<List<Transaction>> watchRecentTransactions() {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .watch();
  }

  /// Get total spent today
  Stream<double> watchSpentToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.transactions)
      ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
      ..where((t) => t.type.equals(TransactionType.expense.index));

    return query.watch().map((transactions) {
      return transactions.fold(0.0, (sum, t) => sum + t.amount);
    });
  }

  /// Watch all transactions sorted by date descending
  Stream<List<Transaction>> watchAllTransactions() {
    return (_db.select(_db.transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<void> deleteTransaction(int id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _db.update(_db.transactions).replace(transaction);
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionsRepository(db);
});
