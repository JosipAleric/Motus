import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:intl/intl.dart';
import '../../providers/refuel/refuel_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';

final isRefuelLoadingProvider = StateProvider<bool>((ref) => false);

class RefuelDetailsScreen extends ConsumerWidget {
  final String refuelId;
  final String carId;

  const RefuelDetailsScreen({
    super.key,
    required this.refuelId,
    required this.carId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refuelAsync = ref.watch(refuelByIdProvider((refuelId: refuelId, carId: carId)));
    final isLoading = ref.watch(isRefuelLoadingProvider);

    Future<void> _deleteRefuel() async {
      ref.read(isRefuelLoadingProvider.notifier).state = true;

      try {
        await ref.read(refuelServiceProvider)?.deleteRefuel(carId: carId, refuelId: refuelId);
        ref.invalidate(refuelByIdProvider((refuelId: refuelId, carId: carId)));
        ref.invalidate(refuelStatsProvider(carId));
        ref.invalidate(refuelsPaginatorProvider(carId));

        if (context.mounted) {
          GoRouter.of(context).pop();
          CustomSnackbar.show(
            context,
            type: AlertType.success,
            title: "Uspješno!",
            message: "Zapis je uspješno obrisan iz baze podataka.",
          );

        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            type: AlertType.error,
            title: "Greška!",
            message: "Došlo je do greške prilikom brisanja zapisa. Pokušajte ponovo kasnije.",
          );
        }
      } finally {
        ref.read(isRefuelLoadingProvider.notifier).state = false;
      }
    }

    String formatDate(DateTime date) => DateFormat('dd.MM.yyyy.').format(date);

    String formatNumber(num n) {
      return n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
    }

    String formatMileage(num mileage) {
      final text = mileage.toStringAsFixed(0);
      if (text.length <= 3) return "$text km";
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        if ((text.length - i) % 3 == 0 && i != 0) buffer.write(' ');
        buffer.write(text[i]);
      }
      return '${buffer.toString()} km';
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: refuelAsync.when(
          data: (data) => data?.car?.brand ?? "Detalji točenja",
          loading: () => "Učitavanje...",
          error: (err, _) => "Greška",
        ),
        subtitle: refuelAsync.when(
          data: (data) => data?.car != null ? "${data!.car.year} ${data.car.model}" : "",
          loading: () => "Učitavanje...",
          error: (err, _) => "",
        ),
      ),
      body: refuelAsync.when(
        data: (data) {
          if (data == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message: "Zapis nije pronađen u bazi podataka.",
              ),
            );
          }

          final refuel = data.refuel;
          final car = data.car;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        IconifyIcon(
                          icon: 'mdi:chevron-right',
                          color: Colors.black87,
                          size: 24,
                        ),
                        const Text(
                          'Detalji točenja',
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66CC8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          IconifyIcon(
                            icon: 'solar:check-read-broken',
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Evidentirano",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                buildRefuelDetailColumn(
                  "Datum točenja",
                  formatDate(refuel.date),
                  'lets-icons:date-range-light',
                ),
                buildRefuelDetailColumn(
                  "Kilometraža pri točenju",
                  formatMileage(refuel.mileageAtRefuel),
                  'stash:data-numbers',
                ),
                buildRefuelDetailColumn(
                  "Litara goriva",
                  "${formatNumber(refuel.liters)} L",
                  'mdi:gas-pump',
                ),
                buildRefuelDetailColumn(
                  "Cijena po litru",
                  "${formatNumber(refuel.pricePerLiter)} BAM",
                  'material-symbols:attach-money-rounded',
                ),
                buildRefuelDetailColumn(
                  "Ukupna cijena",
                  "${formatNumber(refuel.price)} BAM",
                  'mdi:cash',
                ),
                buildRefuelDetailColumn(
                  "Korišten aditiv",
                  refuel.usedFuelAditives ? "Da" : "Ne",
                  'mdi:flask-outline',
                ),
                buildRefuelDetailColumn(
                  "Benzinska pumpa",
                  refuel.gasStation?.isNotEmpty == true ? refuel.gasStation! : "Nije navedeno",
                  'mdi:fuel',
                ),
                buildRefuelDetailColumn(
                  "Napomene",
                  refuel.notes?.isNotEmpty == true ? refuel.notes! : "Nema napomena",
                  'hugeicons:note',
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          GoRouter.of(context).pushNamed(
                            'update_refuel',
                            pathParameters: {
                              'refuelId': refuel.id,
                              'carId': car.id,
                            },
                          );
                        },
                        text: 'Uredi',
                        icon: 'tabler:edit',
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: 5.0,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.divider)),
                    SizedBox(width: 10),
                    Text(
                      'ili',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 15),

                SizedBox(
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
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Potvrda brisanja'),
                            content: const Text(
                                'Jeste li sigurni da želite obrisati ovaj zapis? Ova akcija se ne može poništiti.'),
                            actions: [
                              TextButton(
                                child: const Text('Otkaži'),
                                onPressed: () => GoRouter.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text(
                                  'Obriši',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  GoRouter.of(context).pop();
                                  _deleteRefuel();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                            : const IconifyIcon(
                          icon: "fluent:delete-32-regular",
                          size: 20,
                          color: Colors.red,
                        ),
                        SizedBox(width: isLoading ? 0 : 10),
                        Text(
                          isLoading ? '' : 'Obriši zapis',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Greška: $err")),
      ),
    );
  }

  Column buildRefuelDetailColumn(
      String title,
      String value,
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
              title,
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
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 4),
      ],
    );
  }
}
