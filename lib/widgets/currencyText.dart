import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/currency_provider.dart';

class CurrencyText extends ConsumerWidget {
  final double value;
  final TextStyle? style;

  const CurrencyText(this.value, {this.style, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(priceFormatterProvider);
    return Text(
      format(value),
      style: style,
    );
  }
}

