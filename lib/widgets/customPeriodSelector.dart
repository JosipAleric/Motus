import 'package:flutter/material.dart';

enum PeriodType { week, month, year, custom }

class PeriodSelector extends StatelessWidget {
  final PeriodType selected;
  final ValueChanged<PeriodType> onChanged;
  final VoidCallback onCustomRangeTap;

  const PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.onCustomRangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      PeriodType.week: "7 dana",
      PeriodType.month: "30 dana",
      PeriodType.year: "1 god",
      PeriodType.custom: "Prilagođeno",
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.entries.map((entry) {
        final active = entry.key == selected;
        return ChoiceChip(
          label: Text(entry.value),
          selected: active,
          onSelected: (_) {
            if (entry.key == PeriodType.custom) {
              onCustomRangeTap();
            } else {
              onChanged(entry.key);
            }
          },
        );
      }).toList(),
    );
  }
}
