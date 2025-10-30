import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import '../../models/car_model.dart';
import '../../models/service_car_model.dart';
import '../../providers/car_provider.dart';
import '../../providers/service/service_provider.dart';
import '../../widgets/customServiceCard.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../theme/app_theme.dart';
import '../../widgets/paginationWidget.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: carsAsync.when(
            data: (cars) => cars.isEmpty
                ? const CustomAlert(
                    type: AlertType.info,
                    title: "Nema vozila",
                    message: "Dodajte vozilo da biste vidjeli servise.",
                  )
                : const CircularProgressIndicator(),
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Greška: $err'),
          ),
        ),
      );
    }

    final paginatorState = ref.watch(
      servicesPaginatorProvider(_selectedCarId!),
    );
    final paginatorNotifier = ref.read(
      servicesPaginatorProvider(_selectedCarId!).notifier,
    );

    return Scaffold(
      appBar: const CustomAppBar(title: 'Servisi'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    SizedBox(width: 1),
                    Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: IconifyIcon(
                        icon: 'icon-park-outline:right',
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
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


            RefreshIndicator(
              onRefresh: () async {
                paginatorNotifier.reset();
                await paginatorNotifier.loadPage(0);
                ref.invalidate(servicesForCarProvider(_selectedCarId!));
              },
              child: PaginationWidget<ServiceCar>(
                outerScrollable: true,
                state: paginatorState,
                notifier: paginatorNotifier,
                emptyMessage: "Nemate evidentiranih servisa. Dodajte novi servis kako biste pratili održavanje vašeg vozila.",
                itemBuilder: (context, serviceCar) {
                  final service = serviceCar.service;
                  final car = serviceCar.car;

                  return CustomServiceCard(
                      carModel: car.model,
                      carBrand: car.brand,
                      date: service.date,
                      description: service.type,
                      price: '${service.price.toStringAsFixed(2)}',
                      onDetailsTap: () {
                        GoRouter.of(context).pushNamed(
                          'service_details',
                          pathParameters: {
                            'serviceId': service.id,
                            'carId': car.id,
                          },
                        );
                      },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCarDropdown(AsyncValue<List<CarModel>> carsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) return const Text('Nema dodanih vozila.');
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                menuMaxHeight: 400,
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
