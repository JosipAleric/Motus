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

// Paginacija servisa (npr. screen "Svi servisi")
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

// Zadnji servisi vezani uz usera (HOME PAGE)
final latestServicesWithCarProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = _getServiceInstance(ref);
  if (service == null) return [];

  return service.getLatestServicesWithCar();
});

// Lista servisa po vozilu (Future)
final servicesForCarProvider =
FutureProvider.autoDispose.family<List<ServiceCar>, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return [];

  return service.getServicesForCar(carId);
});

// Lista servisa po vozilu (Stream)
final servicesForCarStreamProvider =
StreamProvider.autoDispose.family<List<ServiceCar>, String>((ref, carId) {
  final service = _getServiceInstance(ref);
  if (service == null) return const Stream.empty();

  return service.getServicesForCarStream(carId);
});

// Zadnji servis za vozilo
final lastServiceForCarProvider =
FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return null;

  return service.getLastServiceForCar(carId);
});

// Detalji pojedinačnog servisa
final serviceDetailsWithCarProvider =
FutureProvider.autoDispose.family<ServiceCar?, (String, String)>((ref, ids) async {
  final (carId, serviceId) = ids;
  final service = _getServiceInstance(ref);
  if (service == null) return null;

  return service.getServiceWithCar(carId, serviceId);
});