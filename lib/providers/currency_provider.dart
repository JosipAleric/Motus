// features/currency/providers/currency_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motus/providers/user_provider.dart';
import '../services/currency_service.dart';

final currencyServiceProvider = Provider((ref) => CurrencyService());

final currencyStreamProvider = StreamProvider<String>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((d) => d.data()?['preferred_currency'] ?? 'eur');
});

final setCurrencyProvider = Provider((ref) {
  return (String currency) async {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({"preferred_currency": currency});
  };
});

final exchangeRatesProvider = Provider<Map<String, double>>((ref) {
  return {
    "eur": 1.0,
    "usd": 1.09,
    "bam": 1.95583
  };
});

final priceFormatterProvider = Provider<Function(double)>((ref) {
  final currency = ref.watch(currencyStreamProvider).value ?? 'eur';
  final rates = ref.watch(exchangeRatesProvider);

  String format(double eurPrice) {
    final rate = rates[currency.toLowerCase()] ?? 1.0;
    final converted = eurPrice * rate;
    final formatted = converted.toStringAsFixed(0);
    return "$formatted ${currency.toUpperCase()}";
  }

  return format;
});

