import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';
import '../models/refuel_model.dart';

class CarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream svih auta korisnika
  Stream<List<CarModel>> getCarsForUserStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .orderBy('year', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => CarModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Stream za pojedinačni auto
  Stream<CarModel?> getCarByIdStream(String userId, String carId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CarModel.fromMap(doc.data()!, doc.id);
        });
  }

  // Dohvati sve aute jednom - future
  Future<List<CarModel>> getCarsForUser(String userId) async {
    try {
      final querySnapshot = await _db.collection('users')
          .doc(userId)
          .collection('cars')
          .orderBy('year', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => CarModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Greška pri dohvaćanju auta: $e");
      return [];
    }
  }

  // Dohvati auto jednom - future
  Future<CarModel?> getCarById(String userId, String carId) async {
    try {
      final docSnapshot = await _db.collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return CarModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      print("Greška pri dohvaćanju auta: $e");
      return null;
    }
  }

  // Ažuriraj kilometražu auta pri servisu ili tocenju goriva
  Future<void> updateCarMileage(
    String userId,
    String carId,
    int newMileage,
  ) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId);
    await ref.set({'mileage': newMileage}, SetOptions(merge: true));
  }

  // CRUD operacije
  Future<DocumentReference<Map<String, dynamic>>> addCar(
    String userId,
    CarModel car,
  ) async {
    final ref = _db.collection('users').doc(userId).collection('cars').doc();
    await ref.set(car.copyWith(id: ref.id).toMap());
    return ref;
  }

  Future<void> updateCar(String userId, String carId, CarModel car) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId);
    await ref.set(car.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCar(String userId, String carId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .delete();
  }
}
