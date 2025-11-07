import 'package:flutter/material.dart';
import 'package:motus/widgets/currencyText.dart';
import '../theme/app_theme.dart';

class ChartLine extends StatelessWidget {
  const ChartLine({
    required Key key,
    required this.rate,
    required this.title,
    required this.number,
    this.reversed = false,
    this.suffix = "",
  })  : assert(rate > 0),
        assert(rate <= 1),
        super(key: key);

  final double rate;
  final String title;
  final int number;
  final bool reversed;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final lineWidget = constraints.maxWidth * rate;

      final textRow = Container(
        constraints: BoxConstraints(minWidth: lineWidget),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54
                ),
              ),

              if (suffix.isNotEmpty)
                Text(
                  '$number $suffix',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (suffix.isEmpty)
                CurrencyText(
                  number.toDouble(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );

      final lineBar = Container(
        height: 20,
        width: lineWidget,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reversed
              ? [lineBar, SizedBox(height: 5), textRow]
              : [textRow, SizedBox(height: 5), lineBar],
        ),
      );
    });
  }
}
