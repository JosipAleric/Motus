import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'user_provider.dart';

final carServiceProvider = Provider<CarService>((ref) => CarService());

// StreamProvider za listu auta korisnika
final carsProvider = StreamProvider<List<CarModel>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarsForUser(authUser.uid);
});

// StreamProvider za detalje određenog auta po ID-u
final carDetailsProvider = StreamProvider.family<CarModel?, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarById(authUser.uid, carId);
});


