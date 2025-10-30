import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/theme/app_theme.dart';

class CarCard extends StatelessWidget {
  final String brand;
  final String model;
  final String imageUrl;
  final String badgeText;
  final int year;
  final int mileage;
  final VoidCallback onDetailsTap;

  const CarCard({
    Key? key,
    required this.brand,
    required this.model,
    required this.imageUrl,
    required this.year,
    required this.mileage,
    required this.badgeText,
    required this.onDetailsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    String formattedMileage (int mileage) {
      switch(mileage.toString().length) {
        case 4:
          return mileage.toString().substring(0, 1) + ' ' + mileage.toString().substring(1) + ' km';
        case 5:
          return mileage.toString().substring(0, 2) + ' ' + mileage.toString().substring(2) + ' km';
        case 6:
          return mileage.toString().substring(0, 3) + ' ' + mileage.toString().substring(3) + ' km';
        default:
          return mileage.toString() + ' km';
      }
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left:10, right:8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MPlus1',
                            letterSpacing: 1.3
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          model,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF737373),
                            letterSpacing: 1.2
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF2F).withOpacity(0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Color(0xFF38DA55),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),
              Center(
                child: Image.asset(
                  'assets/images/car.png',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),

              Row(
                children: [
                  _infoChip(
                    icon: 'lets-icons:road-fill',
                    label: formattedMileage(mileage),
                  ),
                  const SizedBox(width: 8),
                  _infoChip(
                    icon: 'mynaui:calendar-down-solid',
                    label: year.toString(),
                  ),
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
              const EdgeInsets.symmetric(horizontal:30, vertical: 14),
              child: Row(
                children: const [
                  IconifyIcon(
                    icon: 'solar:arrow-right-broken',
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Detalji",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 1.2,
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

  Widget _infoChip({required String icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconifyIcon(icon: icon, size: 15, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(
                0xFF606060)),
          ),
        ],
      ),
    );
  }
}
