import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motus/widgets/customButton.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../providers/car_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/carCard.dart';
import '../widgets/customAlert.dart';
import '../widgets/customAppBar.dart';
import '../widgets/customServiceCard.dart';
import '../widgets/customSnackbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final user = ref.watch(currentUserStreamProvider);
    final carsAsync = ref.watch(carsProvider);
    final latestServices = ref.watch(lastestServicesWithCarProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Moja vozila',
        showAddCarButton: true,
      ),
      body: user.when(
        data: (user) {
          if (user == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CustomAlert(
                type: AlertType.info,
                title: "Greška",
                message: "Korisnik nije prijavljen.",
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                carsAsync.when(
                  data: (cars) {
                    if (cars.isEmpty) {
                      return const CustomAlert(
                        type: AlertType.info,
                        title: 'Obavijest',
                        message:
                        'Nemate registriranih vozila. Dodajte novo vozilo klikom na + gumb u gornjem desnom kutu.',
                      );
                    } else {
                      return Column(
                        children: [
                          Column(
                            children: List.generate(cars.length, (index) {
                              final car = cars[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: CarCard(
                                  brand: car.brand,
                                  model: car.model,
                                  imageUrl: "/assets/images/car.png",
                                  year: car.year,
                                  mileage: 182460,
                                  badgeText: "lorem",
                                  onDetailsTap: () {
                                    GoRouter.of(context).push(
                                      '/car_details/${car.id}',
                                    );
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Posljednji servisi',
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
                                        blurRadius: 1),
                                  ],
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
                          latestServices.when(
                            data: (serviceWithCar) {
                              if (serviceWithCar.isEmpty) {
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

                              return Column(
                                children: serviceWithCar.map((entry) {
                                  final car = entry['car'];
                                  final service = entry['service'];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: CustomServiceCard(
                                      carBrand: car.brand,
                                      carModel: car.model,
                                      description: service.type,
                                      date: service.date,
                                      price: service.price.toString(),
                                      onDetailsTap: () {
                                        GoRouter.of(context).pushNamed(
                                          'service_details',
                                          pathParameters: {
                                            'carId': car.id,
                                            'serviceId': service.id,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Text("Greška: $e"),
                          ),
                        ],
                      );
                    }
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Greška: $e')),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Greška: $error')),
      ),
    );
  }
}
