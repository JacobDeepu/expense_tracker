/// Onboarding card data model
class OnboardingCard {
  final String name;
  final double estimatedAmount;
  final String category;
  final String? description;

  const OnboardingCard({
    required this.name,
    required this.estimatedAmount,
    required this.category,
    this.description,
  });

  String get formattedAmount => '₹${estimatedAmount.toStringAsFixed(0)}';
}

/// Sample onboarding cards with common Indian expenses
final List<OnboardingCard> sampleOnboardingCards = [
  const OnboardingCard(
    name: 'Rent',
    estimatedAmount: 15000,
    category: 'Housing',
    description: 'Monthly rent payment',
  ),
  const OnboardingCard(
    name: 'Netflix',
    estimatedAmount: 649,
    category: 'Entertainment',
    description: 'Streaming subscription',
  ),
  const OnboardingCard(
    name: 'Gym Membership',
    estimatedAmount: 2500,
    category: 'Health & Fitness',
    description: 'Monthly gym fees',
  ),
  const OnboardingCard(
    name: 'Groceries',
    estimatedAmount: 5000,
    category: 'Food & Dining',
    description: 'Monthly grocery budget',
  ),
  const OnboardingCard(
    name: 'Transportation',
    estimatedAmount: 3000,
    category: 'Transportation',
    description: 'Ola, Uber, Metro',
  ),
  const OnboardingCard(
    name: 'Electricity Bill',
    estimatedAmount: 1200,
    category: 'Utilities',
    description: 'Monthly electricity',
  ),
  const OnboardingCard(
    name: 'Internet',
    estimatedAmount: 799,
    category: 'Utilities',
    description: 'Broadband connection',
  ),
  const OnboardingCard(
    name: 'Spotify',
    estimatedAmount: 119,
    category: 'Entertainment',
    description: 'Music streaming',
  ),
];
