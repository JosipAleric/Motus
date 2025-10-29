import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'user_provider.dart';

final carServiceProvider = Provider<CarService>((ref) => CarService());

// FutureProvider za listu auta korisnika
final carsProvider = FutureProvider<List<CarModel>>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return [];

  final carService = ref.read(carServiceProvider);
  return await carService.getCarsForUser(authUser.uid);
});

// FutureProvider.family za detalje određenog auta po ID-u
final carDetailsProvider = FutureProvider.family<CarModel?, String>((ref, carId) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return null;

  final carService = ref.read(carServiceProvider);
  return await carService.getCarById(authUser.uid, carId);
});


// StreamProvider za listu auta korisnika
final carsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarsForUserStream(authUser.uid);
});

// StreamProvider za detalje određenog auta po ID-u
final carDetailsStreamProvider = StreamProvider.family<CarModel?, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarByIdStream(authUser.uid, carId);
});



