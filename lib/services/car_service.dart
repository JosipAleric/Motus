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
    final carDocRef = _userCarsCollection.doc(carId);

    try {
      await _deleteSubcollection(carDocRef, 'services');
      await _deleteSubcollection(carDocRef, 'refuels');

      await carDocRef.delete();
      print('Firestore: deleted car document $carId');

      final storagePath = 'users/$userId/cars/$carId/';
      await _deleteStorageFolder(storagePath);

      print('Completed delete for carId: $carId');
    } catch (e) {
      print('Error deleting car: $e');
    }
  }

  Future<void> _deleteSubcollection(DocumentReference parentRef, String subcollectionName) async {
    final subRef = parentRef.collection(subcollectionName);
    final subDocs = await subRef.get();

    for (final doc in subDocs.docs) {
      await doc.reference.delete();
      print('Deleted doc: ${doc.reference.path}');
    }
  }

  Future<void> _deleteStorageFolder(String path) async {
    final folderRef = _storage.ref().child(path);

    try {
      final listResult = await folderRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
        print('Deleted file: ${item.fullPath}');
      }

      for (final prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix.fullPath);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('Storage path not found: $path');
      } else {
        print('Error deleting folder: ${e.code} - ${e.message}');
      }
    }
  }
}
