/// Onboarding card data model
class OnboardingCard {
  final String name;
  final double estimatedAmount;
  final String category;
  final String? description;
  final String imagePath;

  const OnboardingCard({
    required this.name,
    required this.estimatedAmount,
    required this.category,
    this.description,
    this.imagePath = 'assets/images/placeholder.jpg',
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
    imagePath: 'assets/images/onboarding/rent.jpg',
  ),
  const OnboardingCard(
    name: 'Netflix',
    estimatedAmount: 649,
    category: 'Entertainment',
    description: 'Streaming subscription',
    imagePath: 'assets/images/onboarding/netflix.jpg',
  ),
  const OnboardingCard(
    name: 'Gym Membership',
    estimatedAmount: 2500,
    category: 'Health & Fitness',
    description: 'Monthly gym fees',
    imagePath: 'assets/images/onboarding/gym.jpg',
  ),
  const OnboardingCard(
    name: 'Groceries',
    estimatedAmount: 5000,
    category: 'Food & Dining',
    description: 'Monthly grocery budget',
    imagePath: 'assets/images/onboarding/groceries.jpg',
  ),
  const OnboardingCard(
    name: 'Transportation',
    estimatedAmount: 3000,
    category: 'Transportation',
    description: 'Ola, Uber, Metro',
    imagePath: 'assets/images/onboarding/transport.jpg',
  ),
  const OnboardingCard(
    name: 'Electricity Bill',
    estimatedAmount: 1200,
    category: 'Utilities',
    description: 'Monthly electricity',
    imagePath: 'assets/images/onboarding/electricity.jpg',
  ),
  const OnboardingCard(
    name: 'Internet',
    estimatedAmount: 799,
    category: 'Utilities',
    description: 'Broadband connection',
    imagePath: 'assets/images/onboarding/internet.jpg',
  ),
  const OnboardingCard(
    name: 'Spotify',
    estimatedAmount: 119,
    category: 'Entertainment',
    description: 'Music streaming',
    imagePath: 'assets/images/onboarding/spotify.jpg',
  ),
];
