// providers/service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/services/services_service.dart';
import '../../core/pagination/pagination_state.dart';
import '../../models/service_car_model.dart';
import '../user_provider.dart';
import 'service_pagination_notifier.dart';

final _currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value?.uid;
});

final servicesServiceProvider = Provider<ServicesService?>((ref) {
  final userId = ref.watch(_currentUserIdProvider);

  if (userId == null) {
    return null;
  }

  return ServicesService(userId);
});


ServicesService? _getServiceInstance(Ref ref) {
  return ref.watch(servicesServiceProvider);
}

// Paginated services for a specific car
final servicesPaginatorProvider =
StateNotifierProvider.autoDispose.family<ServicesPaginator, PaginationState<ServiceCar>, String>((ref, carId) {
  final userId = ref.watch(_currentUserIdProvider);

  if (userId == null) {
    throw Exception('Paginator se ne može inicijalizirati. Korisnik nije prijavljen.');
  }

  final notifier = ServicesPaginator(ref, carId);

  notifier.loadPage(0);
  return notifier;
});

// Latest services with car details for current user
final latestServicesWithCarProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = _getServiceInstance(ref);
  if (service == null) return [];

  return service.getLatestServicesWithCar();
});

// Services list for a specific car (Future)
final servicesForCarProvider =
FutureProvider.autoDispose.family<List<ServiceCar>, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return [];

  return service.getServicesForCar(carId);
});

// Services list for a specific car (Stream)
final servicesForCarStreamProvider =
StreamProvider.autoDispose.family<List<ServiceCar>, String>((ref, carId) {
  final service = _getServiceInstance(ref);
  if (service == null) return const Stream.empty();

  return service.getServicesForCarStream(carId);
});

// Last service for a specific car
final lastServiceForCarProvider =
FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return null;

  return service.getLastServiceForCar(carId);
});

// Detailed service with car info
final serviceDetailsWithCarProvider =
FutureProvider.autoDispose.family<ServiceCar?, ({String carId, String serviceId})>((ref, params) async {
  final service = _getServiceInstance(ref);
  if (service == null) return null;

  return service.getServiceWithCar(carId: params.carId, serviceId: params.serviceId);
});