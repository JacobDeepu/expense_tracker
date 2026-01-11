import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/tables.dart';
import '../data/notification_service.dart';
import '../data/transactions_repository.dart';
import 'regex_parser.dart';

class TransactionProcessor {
  final NotificationService _notificationService;
  final RegexParser _parser;
  final TransactionsRepository _repository;

  TransactionProcessor(
    this._notificationService,
    this._parser,
    this._repository,
  );

  void initialize() {
    _notificationService.notificationStream.listen((raw) async {
      final parsed = _parser.parse(raw.body);
      
      if (parsed != null) {
        // TODO: Logic to find matching category (future)
        
        await _repository.addTransaction(
          amount: parsed.amount,
          merchantName: parsed.merchant,
          date: raw.timestamp,
          source: TransactionSource.autoNotification,
          type: TransactionType.expense, // Default to expense for now
          rawText: raw.body,
          categoryId: null, // Uncategorized initially
        );
      }
    });
  }
}

final transactionProcessorProvider = Provider<TransactionProcessor>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final repository = ref.watch(transactionsRepositoryProvider);
  final parser = RegexParser();

  return TransactionProcessor(notificationService, parser, repository);
});
