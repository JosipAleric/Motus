class CurrencyService {
  final Map<String, double> eurRate = {
    "eur": 1.0,
    "usd": 1.09,
    "bam": 1.95583,
  };

  double toEur(double value, String fromCurrency) {
    final rate = eurRate[fromCurrency.toLowerCase()];
    if (rate == null) throw ArgumentError('Nepodržana valuta: $fromCurrency');
    final converted = value / rate;
    return double.parse(converted.toStringAsFixed(6));
  }

  double fromEur(double value, String toCurrency) {
    final rate = eurRate[toCurrency.toLowerCase()];
    if (rate == null) throw ArgumentError('Nepodržana valuta: $toCurrency');
    final converted = value * rate;
    return double.parse(converted.toStringAsFixed(2));
  }
}
