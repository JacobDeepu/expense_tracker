import 'package:intl/intl.dart';

/// Mock data service providing realistic Indian lifestyle transactions
/// and recurring rules for presentation purposes.
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  /// Generate realistic Indian lifestyle transactions
  List<MockTransaction> getRecentTransactions() {
    final now = DateTime.now();
    return [
      MockTransaction(
        merchantName: 'SWIGGY',
        amount: 450.0,
        date: now.subtract(const Duration(hours: 2)),
        category: 'Food & Dining',
      ),
      MockTransaction(
        merchantName: 'OLA',
        amount: 180.0,
        date: now.subtract(const Duration(hours: 5)),
        category: 'Transportation',
      ),
      MockTransaction(
        merchantName: 'AMAZON',
        amount: 1299.0,
        date: now.subtract(const Duration(days: 1)),
        category: 'Shopping',
      ),
      MockTransaction(
        merchantName: 'ZOMATO',
        amount: 320.0,
        date: now.subtract(const Duration(days: 1, hours: 3)),
        category: 'Food & Dining',
      ),
      MockTransaction(
        merchantName: 'UBER',
        amount: 245.0,
        date: now.subtract(const Duration(days: 2)),
        category: 'Transportation',
      ),
      MockTransaction(
        merchantName: 'BLINKIT',
        amount: 680.0,
        date: now.subtract(const Duration(days: 2, hours: 4)),
        category: 'Groceries',
      ),
      MockTransaction(
        merchantName: 'FLIPKART',
        amount: 2499.0,
        date: now.subtract(const Duration(days: 3)),
        category: 'Shopping',
      ),
      MockTransaction(
        merchantName: 'STARBUCKS',
        amount: 420.0,
        date: now.subtract(const Duration(days: 3, hours: 2)),
        category: 'Food & Dining',
      ),
    ];
  }

  /// Get recurring rules (monthly subscriptions, utilities, etc.)
  List<MockRecurringRule> getRecurringRules() {
    return [
      MockRecurringRule(
        name: 'Netflix',
        estimatedAmount: 649.0,
        dayOfMonth: 1,
        category: 'Entertainment',
      ),
      MockRecurringRule(
        name: 'Spotify',
        estimatedAmount: 119.0,
        dayOfMonth: 5,
        category: 'Entertainment',
      ),
      MockRecurringRule(
        name: 'Gym Membership',
        estimatedAmount: 2500.0,
        dayOfMonth: 1,
        category: 'Health & Fitness',
      ),
      MockRecurringRule(
        name: 'Rent',
        estimatedAmount: 15000.0,
        dayOfMonth: 1,
        category: 'Housing',
      ),
      MockRecurringRule(
        name: 'Electricity Bill',
        estimatedAmount: 1200.0,
        dayOfMonth: 10,
        category: 'Utilities',
      ),
      MockRecurringRule(
        name: 'Internet',
        estimatedAmount: 799.0,
        dayOfMonth: 15,
        category: 'Utilities',
      ),
    ];
  }

  /// Calculate total expenses for the current month
  double getMonthlyExpenses() {
    final transactions = getRecentTransactions();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return transactions
        .where((t) => t.date.isAfter(monthStart))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get mock monthly budget
  double getMonthlyBudget() {
    return 30000.0; // ₹30,000 monthly budget
  }

  /// Calculate daily limit (Safe to Spend)
  double getDailyLimit() {
    final budget = getMonthlyBudget();
    final expenses = getMonthlyExpenses();
    final remaining = budget - expenses;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;

    if (daysRemaining <= 0) return 0.0;
    return remaining / daysRemaining;
  }

  /// Calculate budget usage percentage (0.0 to 1.0)
  double getBudgetUsage() {
    final budget = getMonthlyBudget();
    final expenses = getMonthlyExpenses();
    return (expenses / budget).clamp(0.0, 1.0);
  }
}

/// Mock transaction model
class MockTransaction {
  final String merchantName;
  final double amount;
  final DateTime date;
  final String category;

  MockTransaction({
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';
}

/// Mock recurring rule model
class MockRecurringRule {
  final String name;
  final double estimatedAmount;
  final int dayOfMonth;
  final String category;

  MockRecurringRule({
    required this.name,
    required this.estimatedAmount,
    required this.dayOfMonth,
    required this.category,
  });

  String get formattedAmount => '₹${estimatedAmount.toStringAsFixed(0)}';
}
