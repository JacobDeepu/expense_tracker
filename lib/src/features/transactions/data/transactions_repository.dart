import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';

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
    return _db.into(_db.transactions).insert(
          TransactionsCompanion(
            amount: Value(amount),
            merchantName: Value(merchantName),
            date: Value(date),
            source: Value(source),
            type: Value(type),
            rawText: Value(rawText),
            categoryId: Value(categoryId),
          ),
        );
  }

  Stream<List<Transaction>> watchRecentTransactions() {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ])
          ..limit(20))
        .watch();
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionsRepository(db);
});

// We need to expose the databaseProvider first. 
// I'll assume it will be created in `lib/src/data/local/database_provider.dart` 
// or I can add it here temporarily, but better to follow structure.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
