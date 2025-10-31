import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/car_model.dart';

class CarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String userId;
  CarService(this.userId);

  CollectionReference<Map<String, dynamic>> get _userCarsCollection =>
      _db.collection('users').doc(userId).collection('cars');

  // Stream of all cars for the user
  Stream<List<CarModel>> getCarsForUserStream() {
    return _userCarsCollection
        .orderBy('year', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => CarModel.fromMap(d.data(), d.id)).toList());
  }

  // Stream of a single car by ID
  Stream<CarModel?> getCarByIdStream(String carId) {
    return _userCarsCollection.doc(carId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CarModel.fromMap(doc.data()!, doc.id);
    });
  }

  //  Future fetch all cars for the user
  Future<List<CarModel>> getCarsForUser() async {
    final querySnapshot =
    await _userCarsCollection.orderBy('year', descending: true).get();
    return querySnapshot.docs
        .map((doc) => CarModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Future fetch a single car by ID
  Future<CarModel?> getCarById(String carId) async {
    final doc = await _userCarsCollection.doc(carId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CarModel.fromMap(doc.data()!, doc.id);
  }


  // CRUD operations

  Future<void> updateCarMileage(String carId, int newMileage) async {
    await _userCarsCollection
        .doc(carId)
        .set({'mileage': newMileage}, SetOptions(merge: true));
  }

  Future<DocumentReference<Map<String, dynamic>>> addCar(CarModel car) async {
    final ref = _userCarsCollection.doc();
    await ref.set(car.copyWith(id: ref.id).toMap());
    return ref;
  }

  Future<void> updateCar(String carId, CarModel car) async {
    await _userCarsCollection
        .doc(carId)
        .set(car.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCar(String carId) async {
    await _userCarsCollection.doc(carId).delete();

    final storagePath = 'users/$userId/cars/$carId/';
    final storageRef = _storage.ref().child(storagePath);

    try {
      final listResult = await storageRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
        print('Deleted file: ${item.fullPath}');
      }

      print('✅ Successfully deleted all car images for carId: $carId');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('Storage path not found or empty: $storagePath');
      } else {
        print('Error deleting car images: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('Unexpected error deleting car: $e');
    }
  }
}
