import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/widgets/currencyText.dart';
import '../theme/app_theme.dart';

class CustomRefuelCard extends StatelessWidget {
  final String carModel;
  final String carBrand;
  final DateTime date;
  final String gasStation;
  final double price;
  final double liters;
  final VoidCallback onDetailsTap;

  const CustomRefuelCard({
    Key? key,
    required this.carModel,
    required this.carBrand,
    required this.date,
    required this.price,
    required this.onDetailsTap,
    required this.liters,
    this.gasStation = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carBrand,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF606060),
                            letterSpacing: 1.3
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        carModel,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),

                  Text(
                    "${date.day}.${date.month}.${date.year}.",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "Natočeno gorivo u vozilo ${carBrand} ${carModel}.",
                style: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1
                ),
              ),

              const SizedBox(height: 13),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoChip(icon: "solar:tag-price-bold", label: price.toString(), isPrice: true),
                  const SizedBox(width: 10),
                  _infoChip(icon: "material-symbols-light:local-gas-station-rounded", label: liters.toString() + " L", isPrice: false),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onDetailsTap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: const [
                  IconifyIcon(
                    icon: 'solar:arrow-right-broken',
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Detalji",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        letterSpacing: 1.2
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip({required String icon, required String label, required bool isPrice}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconifyIcon(icon: icon, size: 17, color: Colors.black),
        ),
        const SizedBox(width: 6),

        if (isPrice)
          CurrencyText(
            double.parse(label),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: 1.3,
            ),
          )
        else
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: 1.3),
          ),
      ],
    );
  }
}