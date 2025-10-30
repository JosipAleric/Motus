import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_design/iconify_design.dart';
import '../../providers/service_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;
  final String carId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.carId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(
      serviceDetailsWithCarProvider((carId, serviceId)),
    );

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

    return Scaffold(
      appBar: CustomAppBar(
        title: serviceAsync.when(
          data: (data) => data?.car?.brand ?? "Detalji servisa",
          loading: () => "Učitavanje...",
          error: (err, _) => "Greška",
        ),
        subtitle: serviceAsync.when(
          data: (data) =>
              data?.car != null ? "${data!.car.year} ${data.car.model}" : "",
          loading: () => "Učitavanje...",
          error: (err, _) => "",
        ),
      ),
      body: serviceAsync.when(
        data: (data) {
          if (data == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CustomAlert(
                type: AlertType.info,
                title: "Nema podataka",
                message: "Servis nije pronađen u bazi.",
              ),
            );
          }

          final service = data.service;
          final car = data.car;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                Center(
                  child: Image.asset(
                    'assets/images/car.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: const IconifyIcon(
                            icon: 'mdi:chevron-right',
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                        const Text(
                          'Detalji servisa',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontFamily: "MPlus1",
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 0),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF66CC8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const IconifyIcon(
                            icon: 'solar:check-read-broken',
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Završeno",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                buildServiceDetailColumn(
                  context,
                  "Vrsta servisa",
                  service.type,
                  'tabler:file-description-filled',
                ),
                buildServiceDetailColumn(
                  context,
                  "Datum servisa",
                  '${service.date.day}.${service.date.month}.${service.date.year}.',
                  'lets-icons:date-range-light',
                ),
                buildServiceDetailColumn(
                  context,
                  "Servisni centar",
                  service.service_center,
                  'qlementine-icons:rename-16',
                ),
                buildServiceDetailColumn(
                  context,
                  "Cijena",
                  service.price.toStringAsFixed(2),
                  'material-symbols:attach-money-rounded',
                  suffixText: "BAM",
                ),
                buildServiceDetailColumn(
                  context,
                  "Kilometraža pri servisu",
                  formattedMileage(service.mileage_at_service),
                  'stash:data-numbers',
                  suffixText: "KM",
                ),
                buildServiceDetailColumn(
                  context,
                  "Napomene",
                  service.service_notes.isNotEmpty
                      ? service.service_notes
                      : "Nema napomena.",
                  'hugeicons:note',
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () => {},
                        text: 'Pogledaj račun',
                        icon: 'hugeicons:invoice',
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: 5.0,
                        outlined: true,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: CustomButton(
                        onPressed: () => {},
                        text: 'Uredi',
                        icon: 'tabler:edit',
                        //isLoading: _isLoading,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        letterSpacing: 1.5,
                        borderRadius: 5.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Greška: $err")),
      ),
    );
  }

  Column buildServiceDetailColumn(
    BuildContext context,
    String detailTitle,
    String detailValue,
    String icon, {
    String suffixText = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconifyIcon(icon: icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 5),
            Text(
              detailTitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detailValue,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              if (suffixText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  suffixText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 4),
        Divider(color: AppColors.divider),
        const SizedBox(height: 4),
      ],
    );
  }
}
