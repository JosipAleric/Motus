// providers/service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/services/services_service.dart';
import '../models/service_car_model.dart';
import 'user_provider.dart';

final serviceProvider = Provider<ServicesService>((ref) => ServicesService());

// StreamProvider koji dohvaća sve servise za određeni auto
final servicesForCarStreamProvider = StreamProvider.family<List<ServiceCar>, String>((
  ref,
  carId,
) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final servicesService = ref.read(serviceProvider);
  return servicesService.getServicesForCarStream(authUser.uid, carId);
});

// FutureProvider koji dohvaća sve servise za određeni auto
final servicesForCarProvider = FutureProvider.family<List<ServiceCar>, String>((ref, carId) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return [];
  final servicesService = ref.read(serviceProvider);
  return servicesService.getServicesForCar(authUser.uid, carId);
});

/// FutureProvider koji dohvaća posljednji servis s pripadajućim automobilom
final lastServiceWithCarProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return Future.value(null);

  final servicesService = ref.read(serviceProvider);
  return servicesService.getLastServiceWithCar(authUser.uid);
});

/// FutureProvider koji dohvaća posljednje servise s pripadajućim automobilom
final lastestServicesWithCarProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return [];

  final servicesService = ref.read(serviceProvider);
  return servicesService.getLatestServicesWithCar(authUser.uid);
});

/// FutureProvider.family koji dohvaća detalje servisa s pripadajućim automobilom
final serviceDetailsWithCarProvider = FutureProvider.family<ServiceCar?, (String, String)>((ref, args) async {

  final String carId = args.$1;     // args.$1 je prvi pozicijski argument (carId)
  final String serviceId = args.$2;  // args.$2 je drugi pozicijski argument (serviceId)

  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return null;

  final servicesService = ref.read(serviceProvider);

  return servicesService.getServiceWithCar(
    authUser.uid,
    carId,
    serviceId,
  );
});