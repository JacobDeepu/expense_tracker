import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import '../logic/ocr/receipt_scanner_service.dart';

part 'transaction_items_repository.g.dart';

class TransactionItemsRepository {
  final AppDatabase _db;

  TransactionItemsRepository(this._db);

  /// Add items for a specific transaction
  Future<void> addItemsForTransaction(
    int transactionId,
    List<ReceiptLineItem> items,
  ) async {
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
  }

  /// Get all items for a specific transaction
  Future<List<TransactionItem>> getItemsForTransaction(int transactionId) {
    return (_db.select(
      _db.transactionItems,
    )..where((t) => t.transactionId.equals(transactionId))).get();
  }

  /// Delete all items for a specific transaction (cascade delete handles this automatically)
  Future<void> deleteItemsForTransaction(int transactionId) async {
    await (_db.delete(
      _db.transactionItems,
    )..where((t) => t.transactionId.equals(transactionId))).go();
  }

  /// Update an existing item
  Future<void> updateItem(TransactionItem item) async {
    await _db.update(_db.transactionItems).replace(item);
  }
}

@riverpod
TransactionItemsRepository transactionItemsRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return TransactionItemsRepository(db);
}
