import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'user_provider.dart';

// CarService sam zna koji je trenutni korisnik (uzima iz FirebaseAuth).
final carServiceProvider = Provider<CarService>((ref) => CarService());

// FutureProvider – dohvaća sve aute trenutnog korisnika (jednokratno)
final carsProvider = FutureProvider<List<CarModel>>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return [];

  final carService = ref.read(carServiceProvider);
  return await carService.getCarsForUser();
});

// FutureProvider.family – dohvaća jedan auto po ID-u (jednokratno)
final carDetailsProvider = FutureProvider.family<CarModel?, String>((ref, carId) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return null;

  final carService = ref.read(carServiceProvider);
  return await carService.getCarById(carId);
});

// StreamProvider – real-time stream svih auta korisnika
final carsStreamProvider = StreamProvider<List<CarModel>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarsForUserStream();
});

// StreamProvider.family – real-time stream pojedinačnog auta po ID-u
final carDetailsStreamProvider = StreamProvider.family<CarModel?, String>((ref, carId) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final carService = ref.read(carServiceProvider);
  return carService.getCarByIdStream(carId);
});
