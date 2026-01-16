class StatsData {
  final double totalCreditsAmount; // Total money loaded in credits (€)
  final int totalCoffeesServed; // Total coffees served (all payment methods)
  final double totalRevenue; // Total revenue from coffees (0.50€ per coffee)
  final int totalFidelityCoffees; // Total free coffees earned by students
  final Map<String, int> coffeesByPaymentMethod; // e.g. {'Crédit': 150, 'Espèce': 20}
  final Map<String, int> popularCoffees; // e.g. {'Expresso': 100, 'Allongé': 50}
  final List<DailyStat> salesOverTime; // Coffees served per day
  final List<DailyStat> creditsOverTime; // Money loaded per day

  StatsData({
    required this.totalCreditsAmount,
    required this.totalCoffeesServed,
    required this.totalRevenue,
    required this.totalFidelityCoffees,
    required this.coffeesByPaymentMethod,
    required this.popularCoffees,
    required this.salesOverTime,
    required this.creditsOverTime,
  });

  // Empty state
  factory StatsData.empty() {
    return StatsData(
      totalCreditsAmount: 0.0,
      totalCoffeesServed: 0,
      totalRevenue: 0.0,
      totalFidelityCoffees: 0,
      coffeesByPaymentMethod: {},
      popularCoffees: {},
      salesOverTime: [],
      creditsOverTime: [],
    );
  }
}

class DailyStat {
  final DateTime date;
  final double value; // Can be amount (€) or count (coffees)

  DailyStat(this.date, this.value);
}
