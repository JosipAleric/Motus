// providers/service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/providers/service/service_pagination_notifier.dart';
import 'package:motus/services/services_service.dart';
import '../../core/pagination/pagination_state.dart';
import '../../models/service_car_model.dart';

// ✅ Glavni provider za servisnu logiku
final serviceProvider = Provider<ServicesService>((ref) {
  return ServicesService(ref);
});

// ✅ Paginacija servisa za određeni auto
final servicesPaginatorProvider = StateNotifierProvider.autoDispose
    .family<ServicesPaginator, PaginationState<ServiceCar>, String>((ref, carId) {
  final notifier = ServicesPaginator(ref, carId, pageSize: 4);
  notifier.loadPage(0);
  ref.onDispose(() => notifier.reset());
  return notifier;
});

// ✅ Stream svih servisa za vozilo
final servicesForCarStreamProvider =
StreamProvider.family<List<ServiceCar>, String>((ref, carId) {
  final servicesService = ref.read(serviceProvider);
  return servicesService.getServicesForCarStream(carId);
});

// ✅ Future svih servisa za vozilo
final servicesForCarProvider =
FutureProvider.family<List<ServiceCar>, String>((ref, carId) async {
  final servicesService = ref.read(serviceProvider);
  return servicesService.getServicesForCar(carId);
});

// ✅ Posljednji servis za auto
final lastServiceForCarProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, carId) async {
  final servicesService = ref.read(serviceProvider);
  return servicesService.getLastServiceForCar(carId);
});

// ✅ Zadnji servisi s pripadajućim automobilom
final latestServicesWithCarProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final servicesService = ref.read(serviceProvider);
  return servicesService.getLatestServicesWithCar();
});

// ✅ Detalji određenog servisa s vozilom
final serviceDetailsWithCarProvider =
FutureProvider.family<ServiceCar?, (String, String)>((ref, args) async {
  final (carId, serviceId) = args;
  final servicesService = ref.read(serviceProvider);
  return servicesService.getServiceWithCar(carId, serviceId);
});
