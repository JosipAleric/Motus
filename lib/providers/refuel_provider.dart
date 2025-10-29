import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/refuel_model.dart';
import '../models/refuel_statistics_model.dart';
import '../services/refuel_service.dart';
import 'user_provider.dart';

final refuelServiceProvider = Provider<RefuelService>((ref) => RefuelService());

// FutureProvider za sve refuele određenog auta
final refuelsProvider = FutureProvider.family<List<RefuelModel>, String>((ref, carId) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return [];

  final service = ref.read(refuelServiceProvider);
  return await service.getRefuels(authUser.uid, carId);
});

// FutureProvider za statistiku refuela
final refuelStatsProvider = FutureProvider.family<RefuelStatistics?, String>((ref, carId) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return null;

  final service = ref.read(refuelServiceProvider);
  return await service.getRefuelStatistics(authUser.uid, carId);
});


// StreamProvider za sve refuele određenog auta
final refuelsStreamProvider = StreamProvider.family<List<RefuelModel>, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final service = ref.watch(refuelServiceProvider);
  return service.getRefuelsStream(authUser.uid, carId);
});

// StreamProvider za statistiku
final refuelStatsStreamProvider = StreamProvider.family<RefuelStatistics?, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream.value(null);
  }

  final service = ref.watch(refuelServiceProvider);
  return service.getRefuelStatisticsStream(authUser.uid, carId);
});

