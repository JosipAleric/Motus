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
import '../../widgets/customBarChart.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customServiceCard.dart';
import '../../widgets/customSnackbar.dart';

final loadingProvider = StateProvider<bool>((ref) => false);

class CarDetailsScreen extends ConsumerWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  String formatMileage(int m) {
    final s = m.toString();
    return (s.length <= 3)
        ? "$s km"
        : "${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)} km";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carAsync = ref.watch(carDetailsProvider(carId));
    final latestServiceAsync = ref.watch(lastServiceForCarProvider(carId));
    final isLoading = ref.watch(loadingProvider);

    Future<void> deleteCar() async {
      ref.read(loadingProvider.notifier).state = true;

      try {
        final service = ref.read(carServiceProvider)!;
        await service.deleteCar(carId);

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
      } catch (_) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            type: AlertType.error,
            title: "Greška",
            message: "Došlo je do greške. Pokušajte ponovo.",
          );
        }
      } finally {
        ref.read(loadingProvider.notifier).state = false;
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: carAsync.when(
          data: (car) => car?.brand ?? 'Detalji auta',
          loading: () => 'Učitavanje...',
          error: (_, __) => 'Greška',
        ),
        subtitle: carAsync.when(
          data: (car) {
            if (car == null) return "Detalji auta";
            final text = "${car.year ?? ''} ${car.model ?? ''}".trim();
            return text.isEmpty ? "Detalji auta" : text;
          },
          loading: () => "Učitavanje...",
          error: (_, __) => "Greška",
        ),
      ),
      body: carAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Greška: $err')),
        data: (car) {
          if (car == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message:
                "Greška prilikom učitavanja automobila. Pokušajte kasnije.",
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/images/car.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: InfoChip(
                              icon: 'lets-icons:road-fill',
                              label: 'Kilometraža',
                              text: formatMileage(car.mileage),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: InfoChip(
                              icon: 'solar:fuel-bold',
                              label: 'Gorivo',
                              text: car.fuel_type,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: InfoChip(
                              icon: 'ph:calendar-fill',
                              label: 'Godina',
                              text: car.year.toString(),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: InfoChip(
                              icon: 'fluent:number-row-24-filled',
                              label: 'Registracija',
                              text: car.license_plate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      ServicesOverviewCost(carId: car.id),

                      SectionHeader(
                        title: "Posljednji servis",
                        buttonText: "Vidi sve",
                        onPressed: () =>
                            GoRouter.of(context).goNamed('services'),
                      ),

                      const SizedBox(height: 15),

                      latestServiceAsync.when(
                        loading: () =>
                        const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text("Greška pri učitavanju."),
                        data: (serviceForCar) {
                          if (serviceForCar == null) {
                            return const CustomAlert(
                              type: AlertType.info,
                              title: 'Obavijest',
                              message:
                              'Nemate evidentiranih servisa. Dodajte novi servis.',
                            );
                          }

                          final service = serviceForCar['service'];
                          final c = serviceForCar['car'];

                          return CustomServiceCard(
                            car: c,
                            date: service.date,
                            description: service.type,
                            price: service.price.toStringAsFixed(2),
                            onDetailsTap: () {
                              GoRouter.of(context).pushNamed(
                                'service_details',
                                pathParameters: {
                                  'carId': c.id,
                                  'serviceId': service.id,
                                },
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      SectionHeader(
                        title: "Detalji o vozilu",
                        buttonText: "Uredi",
                        onPressed: () {
                          GoRouter.of(context).pushNamed(
                            'edit_car',
                            pathParameters: {'carId': car.id},
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      DetailsRow("Marka", car.brand, "Model", car.model),
                      DetailsRow("Godina", car.year.toString(), "Mjenjač",
                          car.transmission),
                      DetailsRow("Kilometraža", formatMileage(car.mileage),
                          "Gorivo", car.fuel_type),
                      DetailsRow(
                          "Snaga", "${car.horsepower} KS", "Zapremina",
                          "${car.displacement / 1000} L"),
                      DetailsRow("VIN", car.vin, "Registracija",
                          car.license_plate),
                      DetailsRow(
                          "Pogon",
                          car.drive_type,
                          "Kilovati",
                          car.horsepower != null
                              ? "${(car.horsepower! * 0.745).toStringAsFixed(0)} kW"
                              : "N/A"),

                      const SizedBox(height: 20),

                      DeleteCarButton(
                        isLoading: isLoading,
                        onConfirmDelete: deleteCar,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  final String text;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconifyIcon(
              icon: icon,
              size: 22,
              color: const Color(0xFF252525),
            ),
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

class DetailsRow extends StatelessWidget {
  final String labelLeft;
  final String textLeft;
  final String labelRight;
  final String textRight;

  const DetailsRow(
      this.labelLeft, this.textLeft, this.labelRight, this.textRight,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DetailColumn(labelLeft, textLeft, CrossAxisAlignment.start),
          DetailColumn(labelRight, textRight, CrossAxisAlignment.end),
        ],
      ),
    );
  }
}

class DetailColumn extends StatelessWidget {
  final String label;
  final String text;
  final CrossAxisAlignment align;

  const DetailColumn(this.label, this.text, this.align, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF3E3E3E),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onPressed;

  const SectionHeader({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        SizedBox(
          height: 32,
          child: CustomButton(
            onPressed: onPressed,
            icon: "solar:arrow-right-broken",
            iconSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            text: buttonText,
            outlined: true,
            borderRadius: 20,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class DeleteCarButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onConfirmDelete;

  const DeleteCarButton({
    super.key,
    required this.isLoading,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Potvrda brisanja'),
              content: const Text(
                'Jeste li sigurni da želite obrisati ovo vozilo? Ova akcija je trajna.',
              ),
              actions: [
                TextButton(
                  child: const Text('Otkaži'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Obriši', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirmDelete();
                  },
                ),
              ],
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            else
              const IconifyIcon(
                icon: "fluent:delete-32-regular",
                size: 20,
                color: Colors.red,
              ),
            if (!isLoading) const SizedBox(width: 10),
            if (!isLoading)
              const Text(
                'Obriši vozilo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class ServicesOverviewCost extends ConsumerStatefulWidget {
  final String carId;

  const ServicesOverviewCost({super.key, required this.carId});

  @override
  ConsumerState<ServicesOverviewCost> createState() => _ServicesOverviewCostState();
}

class _ServicesOverviewCostState extends ConsumerState<ServicesOverviewCost> {
  String selectedPeriod = 'year';
  String selectedYear = DateTime.now().year.toString();

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(
      serviceStatsProvider((
      carId: widget.carId,
      period: selectedPeriod,
      year: selectedYear,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pregled potrošnje",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            PeriodDropdown(
              selectedPeriod: selectedPeriod,
              onChanged: (value) {
                setState(() {
                  selectedPeriod = value!;
                  if (value != "year") selectedYear = DateTime.now().year.toString();
                });
              },
            ),
          ],
        ),

        if (selectedPeriod == 'year')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: YearDropdown(
                selectedYear: selectedYear,
                onChanged: (year) => setState(() => selectedYear = year!),
              ),
            ),
          ),

        const SizedBox(height: 15),

        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text("Greška: $err")),
          data: (data) {
            final totalCost = data['totalCost'] ?? 0;
            final totalServices = data['totalServices'] ?? 0;

            if (totalCost == 0 && totalServices == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CustomAlert(
                  type: AlertType.info,
                  title: 'Obavijest',
                  message: 'Nema dostupnih podataka za odabrane filtere.',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(left: 5, right: 40, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChartLine(
                    title: 'Ukupni trošak',
                    number: totalCost.toInt(),
                    rate: 1,
                    key: const Key("cost"),
                  ),
                  const SizedBox(height: 10),
                  ChartLine(
                    title: 'Ukupno odrađenih servisa',
                    number: totalServices.toInt(),
                    rate: 0.7,
                    key: const Key("services"),
                    reversed: true,
                    suffix: " Servisa",
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class PeriodDropdown extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String?> onChanged;

  const PeriodDropdown({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      DropdownMenuItem(value: 'all', child: Text('Cijelo vrijeme')),
      DropdownMenuItem(value: 'month', child: Text('Posljednji mjesec')),
      DropdownMenuItem(value: 'year', child: Text('Po godini')),
    ];

    const textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppColors.textPrimary,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedPeriod,
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: textStyle,
        isDense: true,
        icon: const IconifyIcon(
          icon: 'famicons:chevron-down-outline',
          color: AppColors.textPrimary,
          size: 15,
        ),
      ),
    );
  }
}

class YearDropdown extends StatelessWidget {
  final String selectedYear;
  final ValueChanged<String?> onChanged;

  const YearDropdown({
    super.key,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    final items = List.generate(
      10,
          (i) => DropdownMenuItem(
        value: (currentYear - i).toString(),
        child: Text((currentYear - i).toString()),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Godina:"),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedYear,
              items: items,
              onChanged: onChanged,
              dropdownColor: Colors.white,
              menuMaxHeight: 200,
              icon: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: const IconifyIcon(
                  icon: 'famicons:chevron-down-outline',
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


