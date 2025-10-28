import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';
import '../models/refuel_model.dart';

class CarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream svih auta korisnika
  Stream<List<CarModel>> getCarsForUser(String userId) {
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
  Stream<CarModel?> getCarById(String userId, String carId) {
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

  // Dohvati auto jednom
  Future<CarModel?> getCarOnce(String userId, String carId) async {
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

  // ============================
  // TOČENJE GORIVA
  // ============================
  //
  // Stream<List<RefuelModel>> getRefuels(String userId, String carId) {
  //   return _db
  //       .collection('users')
  //       .doc(userId)
  //       .collection('cars')
  //       .doc(carId)
  //       .collection('refuels')
  //       .orderBy('date', descending: true)
  //       .snapshots()
  //       .map(
  //         (snapshot) => snapshot.docs
  //             .map((d) => RefuelModel.fromMap(d.data(), d.id))
  //             .toList(),
  //       );
  // }
  //
  // Future<void> addRefuel(
  //   String userId,
  //   String carId,
  //   RefuelModel refuel,
  // ) async {
  //   final ref = _db
  //       .collection('users')
  //       .doc(userId)
  //       .collection('cars')
  //       .doc(carId)
  //       .collection('refuels')
  //       .doc();
  //   await ref.set(refuel.copyWith(id: ref.id).toMap());
  // }
  //
  // Future<void> updateRefuel(
  //   String userId,
  //   String carId,
  //   String refuelId,
  //   RefuelModel refuel,
  // ) async {
  //   final ref = _db
  //       .collection('users')
  //       .doc(userId)
  //       .collection('cars')
  //       .doc(carId)
  //       .collection('refuels')
  //       .doc(refuelId);
  //   await ref.set(refuel.toMap(), SetOptions(merge: true));
  // }
  //
  // Future<void> deleteRefuel(
  //   String userId,
  //   String carId,
  //   String refuelId,
  // ) async {
  //   final ref = _db
  //       .collection('users')
  //       .doc(userId)
  //       .collection('cars')
  //       .doc(carId)
  //       .collection('refuels')
  //       .doc(refuelId);
  //   await ref.delete();
  // }

  // 🔹 Izračunaj troškove po vremenskom periodu
  Future<Map<String, double>> getTotalExpenses({
    required String userId,
    required String carId,
    required DateTime from,
    required DateTime to,
  }) async {
    double totalService = 0;
    double totalFuel = 0;

    // Servisi
    final serviceSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .get();

    for (var doc in serviceSnap.docs) {
      totalService += (doc['cost'] as num).toDouble();
    }

    // Gorivo
    final refuelSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('refuels')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .get();

    for (var doc in refuelSnap.docs) {
      totalFuel += (doc['cost'] as num).toDouble();
    }

    return {
      'services': totalService,
      'fuel': totalFuel,
      'total': totalService + totalFuel,
    };
  }
}
