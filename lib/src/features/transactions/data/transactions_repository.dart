import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import '../../../data/local/database_provider.dart';
import '../logic/ocr/receipt_scanner_service.dart';

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
    int? recurringRuleId,
    List<ReceiptLineItem>? items,
  }) async {
    // Default to 'Other' (ID 7) if no category provided
    const int defaultCategoryId = 7;

    // If items are provided, use a transaction to save both atomically
    if (items != null && items.isNotEmpty) {
      return await _db.transaction(() async {
        final transactionId = await _db
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
                recurringRuleId: Value(recurringRuleId),
              ),
            );

        // Insert all items
        await _db.batch((batch) {
          for (final item in items) {
            batch.insert(
              _db.transactionItems,
              TransactionItemsCompanion.insert(
                transactionId: transactionId,
                itemName: item.name,
                amount: item.amount,
                quantity: Value(item.quantity),
                confidence: Value(item.confidence),
              ),
            );
          }
        });

        return transactionId;
      });
    }

    // Standard transaction without items
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
            recurringRuleId: Value(recurringRuleId),
          ),
        );
  }

  /// Watch IDs of recurring rules paid in the current month
  Stream<Set<int>> watchPaidRecurringRuleIds(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);

    final query = _db.select(_db.transactions)
      ..where((t) => t.date.isBetweenValues(firstOfMonth, lastOfMonth))
      ..where((t) => t.recurringRuleId.isNotNull());

    return query.watch().map((transactions) {
      return transactions.map((t) => t.recurringRuleId!).toSet();
    });
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

    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..where((t) => t.type.equals(TransactionType.expense.index)))
        .watch()
        .map(
          (transactions) => transactions.fold(0.0, (sum, t) => sum + t.amount),
        );
  }

  /// Get total income for the current month
  Stream<double> watchMonthlyIncome() {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastOfMonth = DateTime(now.year, now.month + 1, 0);

    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(firstOfMonth, lastOfMonth))
          ..where((t) => t.type.equals(TransactionType.income.index)))
        .watch()
        .map(
          (transactions) => transactions.fold(0.0, (sum, t) => sum + t.amount),
        );
  }

  /// Get total expenses for the current month
  Stream<double> watchMonthlyExpenses() {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastOfMonth = DateTime(now.year, now.month + 1, 0);

    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(firstOfMonth, lastOfMonth))
          ..where((t) => t.type.equals(TransactionType.expense.index)))
        .watch()
        .map(
          (transactions) => transactions.fold(0.0, (sum, t) => sum + t.amount),
        );
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
