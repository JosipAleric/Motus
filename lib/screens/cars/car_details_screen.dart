import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/providers/refuel/refuel_provider.dart';
import 'package:motus/widgets/customAlert.dart';
import 'package:motus/widgets/customAppBar.dart';
import '../../providers/car_provider.dart';
import 'package:iconify_design/iconify_design.dart';

import '../../providers/service/service_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customServiceCard.dart';
import '../../widgets/customSnackbar.dart';

class CarDetailsScreen extends ConsumerWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carAsync = ref.watch(carDetailsProvider(carId));
    final latestServiceForCarAsync = ref.watch(lastServiceForCarProvider(carId));

    void _deleteCar() async {
      try {
        final carDeletionResult = await ref.read(carServiceProvider)!;
        await carDeletionResult.deleteCar(carId);

        if (context.mounted) {
          ref.invalidate(carsProvider);
          ref.invalidate(latestServicesWithCarProvider);
          GoRouter.of(context).pop();
          CustomSnackbar.show(
            context,
            type: AlertType.success,
            title: "Uspjeh",
            message: "Vozilo je uspješno obrisano.",
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            type: AlertType.error,
            title: "Greška",
            message: "Došlo je do greške prilikom brisanja vozila. Pokušajte ponovo.",
          );
        }
      }
    }

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
        title: carAsync.when(
          data: (car) => car?.brand ?? 'Detalji auta',
          loading: () => 'Učitavanje...',
          error: (err, stack) => 'Greška',
        ),
        subtitle: carAsync.when(
          data: (car) =>
              "${car?.year?.toString() ?? ''} ${car?.model ?? ''}"
                  .trim()
                  .isEmpty
              ? "Detalji auta"
              : "${car?.year?.toString() ?? ''} ${car?.model ?? ''}",
          loading: () => "Učitavanje...",
          error: (err, stack) => "Greška",
        ),
      ),
      body: carAsync.when(
        data: (car) {
          if (car == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message: "Automobil nije pronađen.",
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 0.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 40.0,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/images/car.png',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _infoChip(
                              icon: 'lets-icons:road-fill',
                              label: 'Kilometraža',
                              text: formattedMileage(car.mileage)
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: _infoChip(
                              icon: 'solar:tag-price-bold',
                              label: 'Troškovi',
                              text: "2344 BAM",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _infoChip(
                              icon: 'ph:calendar-fill',
                              label: 'Godina',
                              text: car.year.toString(),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: _infoChip(
                              icon: 'fluent:number-row-24-filled',
                              label: 'Registracija',
                              text: car.license_plate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: const Text(
                              'Posljednji servis',
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
                          ),
                          SizedBox(
                            height: 32,
                            child: CustomButton(
                              text: "Vidi sve",
                              onPressed: () {
                                GoRouter.of(context).goNamed('services');
                              },
                              icon: "solar:arrow-right-broken",
                              fontSize: 11,
                              iconSize: 17,
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 20,
                              ),
                              outlined: true,
                              borderRadius: 30.0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      latestServiceForCarAsync.when(
                        data: (serviceForCar) {
                          if (serviceForCar == null) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: CustomAlert(
                                type: AlertType.info,
                                title: 'Obavijest',
                                message:
                                    'Nemate evidentiranih servisa. Dodajte novi servis kako biste pratili održavanje vašeg vozila.',
                              ),
                            );
                          }

                          final service = serviceForCar['service'];
                          final car = serviceForCar['car'];

                          return CustomServiceCard(
                            carModel: car.model,
                            carBrand: car.brand,
                            date: service.date,
                            description: service.type,
                            price: "${service.price.toStringAsFixed(0)}",
                            onDetailsTap: () {
                              GoRouter.of(context).pushNamed(
                                'service_details',
                                pathParameters: {
                                  'carId': car.id,
                                  'serviceId': service.id,
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text("Greška: $e"),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Detalji o vozilu',
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
                          SizedBox(
                            height: 32,
                            child: CustomButton(
                              text: "Uredi",
                              onPressed: () {
                                GoRouter.of(context).pushNamed(
                                  'edit_car',
                                  pathParameters: {
                                    'carId': car.id,
                                  },
                                );
                              },
                              icon: "akar-icons:edit",
                              fontSize: 11,
                              iconSize: 17,
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 20,
                              ),
                              outlined: true,
                              borderRadius: 30.0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      buildDetailsRow('Marka', car.brand, 'Model', car.model),
                      buildDetailsRow('Godina proizvodnje', car.year.toString(), 'Mjenjač', car.transmission),
                      buildDetailsRow('Kilometraža', formattedMileage(car.mileage), 'Vrsta goriva', car.fuel_type),
                      buildDetailsRow('Snaga motora', '${car.horsepower} KS', 'Zapremina motora', '${car.displacement / 1000} L'),
                      buildDetailsRow('VIN', '${car.VIN}', 'Registracijska oznaka', car.license_plate),
                      buildDetailsRow('Pogon', '${car.drive_type}', 'Kilovati', car.horsepower != null ? (car.horsepower! * 0.745).toStringAsFixed(0) + " kW" : 'N/A'),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Obriši vozilo",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Potvrda brisanja'),
                                  content: const Text('Jeste li sigurni da želite obrisati ovo vozilo? Ova akcija se ne može poništiti.'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Otkaži'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Obriši',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _deleteCar();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: "solar:trash-bin-broken",
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 30,
                          ),
                          fontWeight: FontWeight.w700,
                          borderRadius: 10.0,
                          letterSpacing: 3,
                          outlined: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Greška: $err')),
      ),
    );
  }

  Container buildDetailsRow(String labelLeft, String textLeft, String labelRight, String textRight) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        border: BorderDirectional(bottom: BorderSide(color: AppColors.divider))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelLeft,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF3E3E3E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                textLeft,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                labelRight,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF3E3E3E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                textRight,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required String icon,
    required String label,
    required String text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconifyIcon(icon: icon, size: 22, color: Color(0xFF252525)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
