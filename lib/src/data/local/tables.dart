import 'package:drift/drift.dart';

enum TransactionType { expense, income, transfer }

enum TransactionSource { manual, autoNotification, ocr }

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get merchantName => text().withLength(min: 1, max: 255)();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get source => intEnum<TransactionSource>()();
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();
  TextColumn get rawText => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconKey => text().withLength(min: 1, max: 50)();
  TextColumn get colorHex => text().withLength(min: 6, max: 8)();
}

class NotificationPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text().withLength(min: 1, max: 255)();
  TextColumn get regexPattern => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  RealColumn get estimatedAmount => real()();
  IntColumn get dueDate => integer().nullable()(); // 1-31
  IntColumn get frequencyDays => integer().withDefault(const Constant(30))();
  BoolColumn get isVariable => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemName => text().withLength(min: 1, max: 255)();
  RealColumn get amount => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get confidence =>
      real().withDefault(const Constant(1.0))(); // 0.0 to 1.0
}
