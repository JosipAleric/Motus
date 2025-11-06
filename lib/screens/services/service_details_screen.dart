import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:motus/utils/currency_formatter.dart';
import 'package:motus/widgets/customSnackbar.dart';
import '../../providers/service/service_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/currencyText.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customAppBar.dart';
import '../../widgets/customButton.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);

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
      serviceDetailsWithCarProvider((carId: carId, serviceId: serviceId)),
    );

    bool _isLoading = ref.watch(isLoadingProvider);

    Future<void> _deleteService() async {
      ref.read(isLoadingProvider.notifier).state = true;

      try {
        await ref
            .read(servicesServiceProvider)
            ?.deleteService(carId: carId, serviceId: serviceId);
        if (context.mounted) {
          GoRouter.of(context).pop();
          ref.invalidate(
            serviceDetailsWithCarProvider((carId: carId, serviceId: serviceId)),
          );
          ref.invalidate(
            servicesPaginatorProvider(carId),
          );
          ref.invalidate(latestServicesWithCarProvider);
          ref.invalidate(lastServiceForCarProvider);

          CustomSnackbar.show(
            context,
            type: AlertType.success,
            title: "Uspješno!",
            message:
            "Servis je uspješno obrisan iz baze podataka.",
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            type: AlertType.error,
            title: "Greška!",
            message:
            "Došlo je do greške prilikom brisanja servisa. Pokušajte ponovo kasnije.",
          );
        }
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }

    String formattedMileage(int mileage) {
      switch (mileage.toString().length) {
        case 4:
          return mileage.toString().substring(0, 1) +
              ' ' +
              mileage.toString().substring(1) +
              ' km';
        case 5:
          return mileage.toString().substring(0, 2) +
              ' ' +
              mileage.toString().substring(2) +
              ' km';
        case 6:
          return mileage.toString().substring(0, 3) +
              ' ' +
              mileage.toString().substring(3) +
              ' km';
        default:
          return mileage.toString() + ' km';
      }
    }

    final isLoading = ref.watch(isLoadingProvider);

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
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CustomAlert(
                type: AlertType.error,
                title: "Greška",
                message:
                "Servis nije pronađen u bazi. Molimo pokušajte ponovo kasnije.",
              ),
            );
          }

          final service = data.service;
          final car = data.car;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                          padding: EdgeInsets.only(top: 3.0),
                          child: IconifyIcon(
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
                _buildServiceDetailColumn(
                  context,
                  "Vrsta servisa",
                  service.type,
                  'tabler:file-description-filled',
                ),
                _buildServiceDetailColumn(
                  context,
                  "Datum servisa",
                  '${service.date.day}.${service.date.month}.${service.date.year}.',
                  'lets-icons:date-range-light',
                ),
                _buildServiceDetailColumn(
                  context,
                  "Servisni centar",
                  service.service_center,
                  'qlementine-icons:rename-16',
                ),
                _buildServiceDetailColumn(
                  context,
                  "Cijena",
                  formatPrice(service.price, ref)["amount"]! + " " + formatPrice(service.price, ref)["currency"]!,
                  'material-symbols:attach-money-rounded',
                  suffixText: formatPrice(service.price, ref)["currency"]!,
                ),
                _buildServiceDetailColumn(
                  context,
                  "Kilometraža pri servisu",
                  formattedMileage(service.mileage_at_service),
                  'stash:data-numbers',
                  suffixText: "KM",
                ),
                _buildServiceDetailColumn(
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
                        onPressed: () => {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Račun servisa'),
                              content: service.invoiceUrl != null
                                  ? Image.network(service.invoiceUrl!)
                                  : const Text(
                                  'Nema dostupnog računa za ovaj servis.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Zatvori'),
                                ),
                              ],
                            ),
                          )
                        },
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
                        onPressed: () => {
                          GoRouter.of(context).pushNamed(
                            'update_service',
                            pathParameters: {
                              'serviceId': service.id,
                              'carId': car.id,
                            },
                          )
                        },
                        text: 'Uredi',
                        icon: 'tabler:edit',
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        letterSpacing: 1.5,
                        borderRadius: 5.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.divider,
                        thickness: 1,
                      ),
                    ),
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
                    Expanded(
                      child: Divider(
                        color: AppColors.divider,
                        thickness: 1,
                      ),
                    ),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isLoading
                            ? SizedBox(
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
                        SizedBox(width: _isLoading ? 0 : 10),
                        Text(
                          _isLoading ? '' : 'Obriši servis',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Potvrda brisanja'),
                            content: const Text(
                                'Jeste li sigurni da želite obrisati ovaj servis? Ova akcija se ne može poništiti.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Otkaži'),
                                onPressed: () {
                                  GoRouter.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text(
                                  'Obriši',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  GoRouter.of(context).pop();
                                  _deleteService();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
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

  Column _buildServiceDetailColumn(
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
