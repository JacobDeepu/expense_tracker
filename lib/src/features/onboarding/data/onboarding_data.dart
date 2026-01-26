/// Frequency options for recurring expenses
enum ExpenseFrequency {
  daily(1, 'Daily', '/day'),
  weekly(7, 'Weekly', '/week'),
  monthly(30, 'Monthly', '/month'),
  yearly(365, 'Yearly', '/year');

  final int days;
  final String label;
  final String suffix;

  const ExpenseFrequency(this.days, this.label, this.suffix);
}

/// Onboarding card data model
class OnboardingCard {
  final String name;
  final double estimatedAmount;
  final String category;
  final ExpenseFrequency frequency;
  final String? description;

  const OnboardingCard({
    required this.name,
    required this.estimatedAmount,
    required this.category,
    this.frequency = ExpenseFrequency.monthly,
    this.description,
  });

  String get formattedAmount => '₹${estimatedAmount.toStringAsFixed(0)}';

  String get formattedAmountWithFrequency =>
      '₹${estimatedAmount.toStringAsFixed(0)} ${frequency.suffix}';

  /// Create a copy with updated values (for editing)
  OnboardingCard copyWith({
    String? name,
    double? estimatedAmount,
    String? category,
    ExpenseFrequency? frequency,
    String? description,
  }) {
    return OnboardingCard(
      name: name ?? this.name,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
    );
  }
}

/// Core onboarding cards - universal expenses most people have
final List<OnboardingCard> coreOnboardingCards = [
  const OnboardingCard(
    name: 'Groceries',
    estimatedAmount: 5000,
    category: 'Food & Dining',
    frequency: ExpenseFrequency.monthly,
    description: 'Monthly grocery budget',
  ),
  const OnboardingCard(
    name: 'Transportation',
    estimatedAmount: 3000,
    category: 'Transportation',
    frequency: ExpenseFrequency.monthly,
    description: 'Fuel, Ola, Uber, Metro',
  ),
  const OnboardingCard(
    name: 'Mobile & Internet',
    estimatedAmount: 1000,
    category: 'Utilities',
    frequency: ExpenseFrequency.monthly,
    description: 'Phone and broadband bills',
  ),
];
