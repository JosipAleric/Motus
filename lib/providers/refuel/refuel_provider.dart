import 'package:flutter_riverpod/flutter_riverpod.dart';
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
