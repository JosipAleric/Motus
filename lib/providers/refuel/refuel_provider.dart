import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/pagination/pagination_state.dart';
import '../../models/refuel_model.dart';
import '../../models/refuel_statistics_model.dart';
import '../../models/pagination_result.dart';
import '../../services/refuel_service.dart';
import '../user_provider.dart';
import 'refuel_pagination_notifier.dart';

final refuelServiceProvider = Provider<RefuelService>((ref) => RefuelService(ref));

// StateNotifierProvider za paginaciju refuela
final refuelsPaginatorProvider = StateNotifierProvider.autoDispose
    .family<RefuelsPaginator, PaginationState<RefuelModel>, String>((ref, carId) {
  final notifier = RefuelsPaginator(ref, carId);
  notifier.loadPage(0);
  ref.onDispose(notifier.reset);
  return notifier;
});

// FutureProvider za sve refuele određenog auta
final refuelsProvider = FutureProvider.family<List<RefuelModel>, String>((ref, carId) async {
  final service = ref.read(refuelServiceProvider);
  return await service.getRefuels(carId);
});

// FutureProvider za statistiku refuela određenog auta
final refuelStatsProvider = FutureProvider.family<RefuelStatistics?, String>((ref, carId) async {
  final service = ref.read(refuelServiceProvider);
  return await service.getRefuelStatistics(carId);
});

// StreamProvider za refuele određenog auta
final refuelsStreamProvider = StreamProvider.family<List<RefuelModel>, String>((ref, carId) {
  final service = ref.watch(refuelServiceProvider);
  return service.getRefuelsStream(carId);
});

// StreamProvider za statistiku refuela određenog auta
final refuelStatsStreamProvider = StreamProvider.family<RefuelStatistics?, String>((ref, carId) {
  final service = ref.watch(refuelServiceProvider);
  return service.getRefuelStatisticsStream(carId);
});
