class RefuelStatistics {
  final double averageConsumption;
  final double totalCost;
  final double averageCostPerRefuel;
  final int totalRefuels;

  RefuelStatistics({
    required this.averageConsumption,
    required this.totalCost,
    required this.averageCostPerRefuel,
    required this.totalRefuels,
  });

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  String toString() {
    return 'RefuelStatistics(\n'
        '  Prosječna potrošnja: ${_round(averageConsumption)} L/100km,\n'
        '  Ukupno Potrošeno novca: ${_round(totalCost)} BAM,\n'
        '  Prosječna cijena: ${_round(averageCostPerRefuel)},\n'
        '  Ukupno točenja: $totalRefuels\n'
        ')';
  }
}