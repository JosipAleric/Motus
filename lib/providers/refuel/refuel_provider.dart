import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/models/refuel_car_model.dart';
import 'package:motus/services/refuel_service.dart';
import '../../core/pagination/pagination_state.dart';
import '../../models/refuel_model.dart';
import '../../models/refuel_statistics_model.dart';
import '../user_provider.dart';
import 'refuel_pagination_notifier.dart';

final _currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value?.uid;
});

final refuelServiceProvider = Provider<RefuelService?>((ref) {
  final userId = ref.watch(_currentUserIdProvider);
  if (userId == null) return null;
  return RefuelService(userId);
});

RefuelService? _getServiceInstance(Ref ref) {
  return ref.watch(refuelServiceProvider);
}

// All refuels with pagination
final refuelsPaginatorProvider = StateNotifierProvider.autoDispose
    .family<RefuelsPaginator, PaginationState<RefuelModel>, String>((ref, carId) {
  final userId = ref.watch(_currentUserIdProvider);
  if (userId == null) {
    throw Exception('Paginator se ne može inicijalizirati. Korisnik nije prijavljen.');
  }

  final notifier = RefuelsPaginator(ref, carId);
  notifier.loadPage(0);
  return notifier;
});

// ----------------------------------------------------------------------
// Future providers
// ----------------------------------------------------------------------

final refuelsProvider =
FutureProvider.autoDispose.family<List<RefuelModel>, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return [];
  return service.getRefuels(carId);
});

final refuelStatsProvider =
FutureProvider.autoDispose.family<RefuelStatistics?, String>((ref, carId) async {
  final service = _getServiceInstance(ref);
  if (service == null) return null;
  return service.getRefuelStatistics(carId);
});

final refuelByIdProvider = FutureProvider.autoDispose
    .family<RefuelCar?, ({String carId, String refuelId})>((ref, params) async {
  final service = _getServiceInstance(ref);
  if (service == null) return null;

  return service.getRefuelDetailsById(
    refuelId: params.refuelId,
    carId: params.carId,
  );
});



// ----------------------------------------------------------------------
// Stream providers
// ----------------------------------------------------------------------

final refuelsStreamProvider =
StreamProvider.autoDispose.family<List<RefuelModel>, String>((ref, carId) {
  final service = _getServiceInstance(ref);
  if (service == null) return const Stream.empty();
  return service.getRefuelsStream(carId);
});

final refuelStatsStreamProvider =
StreamProvider.autoDispose.family<RefuelStatistics?, String>((ref, carId) {
  final service = _getServiceInstance(ref);
  if (service == null) return const Stream.empty();
  return service.getRefuelStatisticsStream(carId);
});


final refuelGraphProvider = FutureProvider.family
    .autoDispose<Map<String, double>, ({String carId, String period, String year})>((ref, args) async {

  final service = _getServiceInstance(ref);
  if (service == null) return {'totalCost': 0, 'totalLiters': 0};

  // Ako year nije broj (string se šalje), parsiraj ga sigurno
  final parsedYear = int.tryParse(args.year);

  final res = await service.getFuelSummaryForPeriod(
    carId: args.carId,
    period: args.period,
    year: parsedYear, // koristi se samo ako je period == 'year'
  );

  return res;
});

