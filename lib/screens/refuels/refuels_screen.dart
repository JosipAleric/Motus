import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/widgets/customButton.dart';
import 'package:motus/widgets/customRefuelCard.dart';
import 'package:iconify_design/iconify_design.dart';

import '../../models/car_model.dart';
import '../../models/refuel_model.dart';
import '../../providers/car_provider.dart';
import '../../providers/refuel/refuel_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/customAlert.dart';

import '../../widgets/customAppBar.dart';
import '../../widgets/paginationWidget.dart';

class RefuelsScreen extends ConsumerStatefulWidget {
  const RefuelsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RefuelsScreen> createState() => _RefuelsScreenState();
}

class _RefuelsScreenState extends ConsumerState<RefuelsScreen> {
  String? _selectedCarId;

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: "Trip log"),
      body: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) {
            return const Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const CustomAlert(
                type: AlertType.info,
                title: "Obavijest",
                message: "Dodajte vozilo kako biste pratili povijest točenja goriva.",
              ),
            );
          }

          _selectedCarId ??= cars.first.id;

          final selectedCar = cars.firstWhere(
                (car) => car.id == _selectedCarId,
            orElse: () => cars.first,
          );

          return SingleChildScrollView(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_selectedCarId != null) {
                  final paginatorNotifier = ref.read(refuelsPaginatorProvider(_selectedCarId!).notifier);
                  paginatorNotifier.reset();
                  await paginatorNotifier.loadPage(0);
                  ref.invalidate(refuelStatsProvider(_selectedCarId!));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CarDropdown(
                          cars: cars,
                          selectedCarId: _selectedCarId!,
                          onChanged: (value) {
                            setState(() => _selectedCarId = value);
                          },
                        ),
                        SizedBox(
                          height: 35,
                          child: CustomButton(
                            text: "Dodaj zapis",
                            icon: "mdi:add",
                            onPressed: () {
                              if (_selectedCarId != null) {
                                GoRouter.of(context).pushNamed(
                                  'add_refuel',
                                  pathParameters: {'carId': _selectedCarId!},
                                );
                              }
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            fontSize: 10,
                            iconSize: 15,
                            borderRadius: 5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _selectedCarId == null
                        ? const Center(child: Text('Odaberi vozilo'))
                        : RefuelsContent(
                      carId: _selectedCarId!,
                      selectedCar: selectedCar,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška pri dohvaćanju auta: $e')),
      ),
    );
  }
}

class RefuelsContent extends ConsumerWidget {
  final String carId;
  final CarModel selectedCar;

  const RefuelsContent({
    Key? key,
    required this.carId,
    required this.selectedCar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(refuelStatsProvider(carId));
    final paginatorState = ref.watch(refuelsPaginatorProvider(carId));
    final paginatorNotifier = ref.read(refuelsPaginatorProvider(carId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/car.png',
          height: 140,
          width: double.infinity,
          fit: BoxFit.contain,
        ),

        statsAsync.when(
          data: (stats) {
            if (stats == null || stats.totalRefuels == 0) {
              return const Text("");
            }
            return Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _infoChip(
                        icon: 'ix:average',
                        label: 'Potrošnja',
                        text:
                        '${stats.averageConsumption.toStringAsFixed(1)} L/100km',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoChip(
                        icon: 'hugeicons:chart-average',
                        label: "Po točenju",
                        text: '${formatPrice(stats.averageCostPerRefuel, ref)["amount"]!} ${formatPrice(stats.averageCostPerRefuel, ref)["currency"]!}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _infoChip(
                        icon: 'carbon:summary-kpi',
                        label: 'Br. točenja',
                        text: '${stats.totalRefuels} puta',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoChip(
                        icon: 'hugeicons:summation-02',
                        label: "Trošak",
                        text: '${formatPrice(stats.totalCost, ref)["amount"]!} ${formatPrice(stats.totalCost, ref)["currency"]!}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Greška: ${e.toString()}')),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Povijest točenja',
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
            const SizedBox(height: 15),

            PaginationWidget<RefuelModel>(
              state: paginatorState,
              notifier: paginatorNotifier,
              emptyMessage: "Nema zabilježenih točenja goriva za ovo vozilo. Dodajte novi zapis kako biste pravili povijest točenja.",
              outerScrollable: true,
              itemBuilder: (context, refuel) {
                return CustomRefuelCard(
                    carModel: selectedCar.model,
                    carBrand: selectedCar.brand,
                    date: refuel.date,
                    price: refuel.price,
                    liters: refuel.liters,
                    // TODO: Implementirati onDetailsTap logiku za prikaz detalja
                    onDetailsTap: () {
                      GoRouter.of(context).pushNamed(
                        'refuel_details',
                        pathParameters: {
                          'carId': carId,
                          'refuelId': refuel.id,
                        },
                      );
                    },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _CarDropdown extends StatelessWidget {
  final List<CarModel> cars;
  final String selectedCarId;
  final ValueChanged<String?> onChanged;

  const _CarDropdown({
    required this.cars,
    required this.selectedCarId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: Container(
        alignment: Alignment.centerLeft,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCarId,
            menuMaxHeight: 400,
            icon: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 5, top: 2),
              child: const IconifyIcon(
                icon: 'famicons:chevron-down-outline',
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
            selectedItemBuilder: (BuildContext context) {
              return cars.map<Widget>((car) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        car.brand,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        car.model,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            onChanged: onChanged,
            items: cars.map<DropdownMenuItem<String>>((car) {
              return DropdownMenuItem<String>(
                value: car.id,
                child: Text('${car.brand} ${car.model}'),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
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
          child: IconifyIcon(icon: icon, size: 20, color: Color(0xFF252525)),
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