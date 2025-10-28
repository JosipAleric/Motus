import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/screens/services/service_details_screen.dart';
import 'package:motus/widgets/customServiceCard.dart';
import '../../models/car_model.dart';
import '../../models/service_car_model.dart';
import '../../providers/car_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../theme/app_theme.dart';
import 'package:iconify_design/iconify_design.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String? _selectedCarId;

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsProvider);

    carsAsync.whenData((cars) {
      if (_selectedCarId == null && cars.isNotEmpty) {
        _selectedCarId = cars.first.id;
      }
    });

    if (_selectedCarId == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Servisi'),
        body: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: carsAsync.when(
            data: (cars) {
              if (cars.isEmpty) {
                return const CustomAlert(
                  type: AlertType.info,
                  title: "Nema vozila",
                  message: "Dodajte vozilo da biste vidjeli servise.",
                );
              }
              return const CircularProgressIndicator();
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Greška: $err'),
          ),
        ),
      );
    }

    final servicesAsync = ref.watch(servicesForCarProvider(_selectedCarId!));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Servisi'),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: servicesAsync.when(
          data: (services) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 1),
                          const Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: const IconifyIcon(
                              icon: 'icon-park-outline:right',
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'Završeni servisi',
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
                      _buildCarDropdown(carsAsync),
                    ],
                  ),
                  if (services.isEmpty)
                    const CustomAlert(
                      type: AlertType.info,
                      title: "Nema servisa",
                      message: "Dodajte novi servis za ovo vozilo.",
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final serviceCar = services[index];
                            final service = serviceCar.service;
                            final car = serviceCar.car;

                            return Container(
                              margin: EdgeInsets.only(bottom: 20),
                              child: CustomServiceCard(
                                carModel: car.model,
                                carBrand: car.brand,
                                date: service.date,
                                description: service.type,
                                price:
                                    '${service.price.toStringAsFixed(2)} BAM',
                                onDetailsTap: () {
                                  GoRouter.of(context).pushNamed(
                                    'service_details',
                                    pathParameters: {'serviceId': service.id, 'carId': car.id},
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Greška: $error')),
        ),
      ),
    );
  }

  Widget _buildCarDropdown(AsyncValue<List<CarModel>> carsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) {
            return const Text('Nema dodanih vozila.');
          }
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCarId,
                isExpanded: false,
                icon: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(left: 5, top: 5),
                  child: const IconifyIcon(
                    icon: 'famicons:chevron-down-outline',
                    color: AppColors.textPrimary,
                    size: 14,
                  ),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return cars.map<Widget>((car) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${car.model}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList();
                },
                onChanged: (String? newId) {
                  setState(() {
                    _selectedCarId = newId;
                  });
                },
                items: cars.map<DropdownMenuItem<String>>((car) {
                  return DropdownMenuItem<String>(
                    value: car.id,
                    child: Text('${car.brand} ${car.model}'),
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Greška pri učitavanju: $err'),
      ),
    );
  }
}
