import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car_model.dart';

class CarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _userCarsCollection {
    if (_userId == null) throw Exception('Korisnik nije prijavljen.');
    return _db.collection('users').doc(_userId).collection('cars');
  }

  // Stream svih auta korisnika
  Stream<List<CarModel>> getCarsForUserStream() {
    return _userCarsCollection
        .orderBy('year', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => CarModel.fromMap(d.data(), d.id)).toList());
  }

  // Stream za pojedinačni auto
  Stream<CarModel?> getCarByIdStream(String carId) {
    return _userCarsCollection.doc(carId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CarModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Future – dohvaća sve aute
  Future<List<CarModel>> getCarsForUser() async {
    final querySnapshot =
    await _userCarsCollection.orderBy('year', descending: true).get();
    return querySnapshot.docs
        .map((doc) => CarModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Future – dohvaća jedan auto
  Future<CarModel?> getCarById(String carId) async {
    final doc = await _userCarsCollection.doc(carId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CarModel.fromMap(doc.data()!, doc.id);
  }

  // Ažuriraj kilometražu
  Future<void> updateCarMileage(String carId, int newMileage) async {
    await _userCarsCollection
        .doc(carId)
        .set({'mileage': newMileage}, SetOptions(merge: true));
  }

  // Dodaj novi auto
  Future<DocumentReference<Map<String, dynamic>>> addCar(CarModel car) async {
    final ref = _userCarsCollection.doc();
    await ref.set(car.copyWith(id: ref.id).toMap());
    return ref;
  }

  // Ažuriraj auto
  Future<void> updateCar(String carId, CarModel car) async {
    await _userCarsCollection
        .doc(carId)
        .set(car.toMap(), SetOptions(merge: true));
  }

  // Obriši auto
  Future<void> deleteCar(String carId) async {
    await _userCarsCollection.doc(carId).delete();
  }
}
