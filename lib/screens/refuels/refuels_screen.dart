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
import '../../widgets/customBarChart.dart';
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
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CustomAlert(
                type: AlertType.info,
                title: "Obavijest",
                message:
                    "Dodajte vozilo kako biste pratili povijest točenja goriva.",
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
                  final paginatorNotifier = ref.read(
                    refuelsPaginatorProvider(_selectedCarId!).notifier,
                  );
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

class RefuelsContent extends ConsumerStatefulWidget {
  final String carId;
  final CarModel selectedCar;

  const RefuelsContent({
    Key? key,
    required this.carId,
    required this.selectedCar,
  }) : super(key: key);

  @override
  ConsumerState<RefuelsContent> createState() => _RefuelsContentState();
}

class _RefuelsContentState extends ConsumerState<RefuelsContent> {
  String _selectedPeriod = 'year';
  String _selectedYear = DateTime.now().year.toString();

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(refuelStatsProvider(widget.carId));
    final paginatorState = ref.watch(refuelsPaginatorProvider(widget.carId));
    final paginatorNotifier = ref.read(
      refuelsPaginatorProvider(widget.carId).notifier,
    );

    final refuelGraphDataAsync = ref.watch(
      refuelGraphProvider((
        carId: widget.carId,
        period: _selectedPeriod,
        year: _selectedYear,
      )),
    );

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
                        text:
                            '${formatPrice(stats.averageCostPerRefuel, ref)["amount"]!} ${formatPrice(stats.averageCostPerRefuel, ref)["currency"]!}',
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
                        text:
                            '${formatPrice(stats.totalCost, ref)["amount"]!} ${formatPrice(stats.totalCost, ref)["currency"]!}',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTitle("Pregled potrošnje"),
                    _PeriodDropdown(
                      selectedPeriod: _selectedPeriod,
                      selectedYear: _selectedYear,
                      onPeriodChanged: (newPeriod) {
                        setState(() {
                          _selectedPeriod = newPeriod!;
                          if (newPeriod == 'year' && _selectedYear.isEmpty) {
                            _selectedYear = DateTime.now().year.toString();
                          }
                        });
                      },
                      onYearChanged: (newYear) {
                        setState(() {
                          _selectedYear = newYear!;
                        });
                      },
                    ),
                  ],
                ),
                if (_selectedPeriod == 'year')
                  Padding(
                    padding: const EdgeInsets.only(top: 10, right: 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _YearDropdown(
                        selectedYear: _selectedYear,
                        onChanged: (newYear) {
                          setState(() {
                            _selectedYear = newYear!;
                          });
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 15),
                refuelGraphDataAsync.when(
                  data: (data) {
                    if (data['totalCost'] == 0 && data['totalLiters'] == 0) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: CustomAlert(
                            type: AlertType.info,
                            title: 'Obavijest',
                            message:
                                'Nema dostupnih podataka za odabrane filtere.',
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 40,
                        left: 5,
                        bottom: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChartLine(
                            title: 'Ukupni trošak goriva',
                            number: data['totalCost']!.toInt(),
                            rate: 1,
                            key: const Key("cost"),
                          ),
                          const SizedBox(height: 10),
                          ChartLine(
                            title: 'Ukupno litara goriva',
                            number: data['totalLiters']!.toInt(),
                            rate: 0.7,
                            key: const Key("liters"),
                            reversed: true,
                            suffix: " Litara",
                          ),
                        ],
                      ),
                    );
                  },
                  error: (e, _) =>
                      Center(child: Text('Greška: ${e.toString()}')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),


                _buildTitle("Povijest točenja"),
                const SizedBox(height: 15),

                PaginationWidget<RefuelModel>(
                  state: paginatorState,
                  notifier: paginatorNotifier,
                  emptyMessage:
                      "Nema zabilježenih točenja goriva za ovo vozilo. Dodajte novi zapis kako biste pravili povijest točenja.",
                  outerScrollable: true,
                  itemBuilder: (context, refuel) {
                    return CustomRefuelCard(
                      carModel: widget.selectedCar.model,
                      carBrand: widget.selectedCar.brand,
                      date: refuel.date,
                      price: refuel.price,
                      liters: refuel.liters,
                      onDetailsTap: () {
                        GoRouter.of(context).pushNamed(
                          'refuel_details',
                          pathParameters: {
                            'carId': widget.carId,
                            'refuelId': refuel.id,
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 25),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Row _buildTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: IconifyIcon(
            icon: 'icon-park-outline:right',
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          title,
          style: const TextStyle(
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

class _PeriodDropdown extends StatelessWidget {
  final String selectedPeriod;
  final String selectedYear;
  final ValueChanged<String?> onPeriodChanged;
  final ValueChanged<String?> onYearChanged;

  const _PeriodDropdown({
    required this.selectedPeriod,
    required this.selectedYear,
    required this.onPeriodChanged,
    required this.onYearChanged,
  });

  String _getLabel(String value) {
    switch (value) {
      case 'all':
        return 'Cijelo vrijeme';
      case 'month':
        return 'Posljednji mjesec';
      case 'year':
        return 'Po godini';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> periodOptions = [
      const DropdownMenuItem(value: 'all', child: Text('Cijelo vrijeme')),
      const DropdownMenuItem(value: 'month', child: Text('Posljednji mjesec')),
      const DropdownMenuItem(value: 'year', child: Text('Po godini')),
    ];

    const textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppColors.textPrimary,
    );

    return IntrinsicWidth(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          isDense: true,
          isExpanded: true,
          dropdownColor: Colors.white,

          selectedItemBuilder: (BuildContext context) {
            return periodOptions.map((item) {
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _getLabel(item.value!),
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },

          icon: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 5, top: 2),
            child: const IconifyIcon(
              icon: 'famicons:chevron-down-outline',
              color: AppColors.textPrimary,
              size: 15,
            ),
          ),

          onChanged: onPeriodChanged,
          items: periodOptions,
          style: textStyle,
        ),
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final String selectedYear;
  final ValueChanged<String?> onChanged;

  const _YearDropdown({required this.selectedYear, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final List<DropdownMenuItem<String>> yearOptions = [
      for (int i = 0; i < 10; i++)
        DropdownMenuItem(
          value: (currentYear - i).toString(),
          child: Text((currentYear - i).toString()),
        ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            "Godina:",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: selectedYear,
              menuMaxHeight: 200,
              icon: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(left: 5, top: 2),
                child: const IconifyIcon(
                  icon: 'famicons:chevron-down-outline',
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ),
              onChanged: onChanged,
              items: yearOptions,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
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
          child: IconifyIcon(
            icon: icon,
            size: 20,
            color: const Color(0xFF252525),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
