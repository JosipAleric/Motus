import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';

Map<String, String> formatPrice(double price, WidgetRef ref) {
  final currency = ref.watch(currencyStreamProvider).value ?? 'eur';
  final rates = ref.watch(exchangeRatesProvider);

  final converted = price * (rates[currency.toLowerCase()] ?? 1);
  return {
    'amount': converted.toStringAsFixed(2),
    'currency': currency.toUpperCase(),
  };
}
