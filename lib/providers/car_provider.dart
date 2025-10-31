import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'user_provider.dart';

final _currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value?.uid;
});

// Automatski injektira userId u servis
final carServiceProvider = Provider<CarService?>((ref) {
  final userId = ref.watch(_currentUserIdProvider);

  if (userId == null) {
    return null;
  }
  return CarService(userId);
});

// FutureProvider – dohvaća sve aute trenutnog korisnika
final carsProvider = FutureProvider.autoDispose<List<CarModel>>((ref) async {
  final carService = ref.watch(carServiceProvider);
  if (carService == null) return [];
  return await carService.getCarsForUser();
});

// FutureProvider.family – dohvaća jedan auto po ID-u
final carDetailsProvider =
FutureProvider.autoDispose.family<CarModel?, String>((ref, carId) async {
  final carService = ref.watch(carServiceProvider);
  if (carService == null) return null;
  return await carService.getCarById(carId);
});

// StreamProvider – real-time stream svih auta korisnika
final carsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  final carService = ref.watch(carServiceProvider);
  if (carService == null) return const Stream.empty();
  return carService.getCarsForUserStream();
});

// StreamProvider.family – real-time stream pojedinačnog auta
final carDetailsStreamProvider =
StreamProvider.family<CarModel?, String>((ref, carId) {
  final carService = ref.watch(carServiceProvider);
  if (carService == null) return const Stream.empty();
  return carService.getCarByIdStream(carId);
});
