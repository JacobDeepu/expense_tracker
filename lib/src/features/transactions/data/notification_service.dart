import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_raw.dart';

class NotificationService {
  static const _channel = EventChannel('com.example.expense_tracker/notifications');

  Stream<TransactionRaw> get notificationStream {
    return _channel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return TransactionRaw.fromMap(event);
      }
      throw FormatException('Invalid notification data received');
    });
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationStreamProvider = StreamProvider<TransactionRaw>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});
