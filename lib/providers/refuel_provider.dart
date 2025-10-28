import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/refuel_model.dart';
import '../services/refuel_service.dart';
import 'user_provider.dart';

final refuelServiceProvider = Provider<RefuelService>((ref) => RefuelService());

// 🔹 StreamProvider za sve refuele određenog auta
final refuelsProvider = StreamProvider.family<List<RefuelModel>, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final service = ref.watch(refuelServiceProvider);
  return service.getRefuels(authUser.uid, carId);
});

// 🔹 FutureProvider za statistiku
final refuelStatsProvider = StreamProvider.family<RefuelStatistics?, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream.value(null);
  }

  final service = ref.watch(refuelServiceProvider);
  return service.getRefuelStatistics(authUser.uid, carId);
});
