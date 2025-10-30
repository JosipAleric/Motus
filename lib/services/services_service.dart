import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';

class ServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper funkcija za dohvaćanje detalja o automobilu
  Future<CarModel> _getCarDetails(String userId, String carId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .get();

    return CarModel.fromMap(doc.data()!, doc.id);
  }

  // Glavna stream funkcija koja spaja servise i automobil
  Stream<List<ServiceCar>> getServicesForCarStream(
    String userId,
    String carId,
  ) {
    final Future<CarModel> carDetailsFuture = _getCarDetails(userId, carId);

    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => ServiceModel.fromMap(d.data(), d.id))
              .toList(),
        )
        .asyncMap((serviceList) async {
          final CarModel car = await carDetailsFuture;

          return serviceList.map((service) {
            return ServiceCar(service: service, car: car);
          }).toList();
        });
  }

  // Future verzija dohvaćanja servisa s pripadajućim automobilom
  Future<List<ServiceCar>> getServicesForCar(
    String userId,
    String carId,
  ) async {
    final car = await _getCarDetails(userId, carId);
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((d) {
      final service = ServiceModel.fromMap(d.data(), d.id);
      return ServiceCar(service: service, car: car);
    }).toList();
  }

  // Dohvati detalje servisa s pripadajućim automobilom
  Future<ServiceCar?> getServiceWithCar(
    String userId,
    String carId,
    String serviceId,
  ) async {
    final serviceDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId)
        .get();

    if (!serviceDoc.exists) return null;

    final serviceData = serviceDoc.data()!;
    final car = await _getCarDetails(userId, carId);

    return ServiceCar(
      service: ServiceModel.fromMap(serviceData, serviceDoc.id),
      car: car,
    );
  }

  // Dohvati posljednji servis s pripadajućim automobilom
  Future<Map<String, dynamic>?> getLastServiceWithCar(String userId) async {
    final carsSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .get();

    Map<String, dynamic>? latestServiceData;
    DateTime? latestDate;

    for (var carDoc in carsSnap.docs) {
      final car = CarModel.fromMap(carDoc.data(), carDoc.id);

      // Dohvati posljednji servis za auto
      final serviceSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(car.id)
          .collection('services')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (serviceSnap.docs.isEmpty) continue;

      final serviceDoc = serviceSnap.docs.first;
      final service = ServiceModel.fromMap(serviceDoc.data(), serviceDoc.id);

      if (latestDate == null || service.date.isAfter(latestDate)) {
        latestDate = service.date;
        latestServiceData = {'car': car, 'service': service};
      }
    }

    return latestServiceData;
  }

  // Dohvati posljednja dva servisa s pripadajućim automobilom
  Future<List<Map<String, dynamic>>> getLatestServicesWithCar(
    String userId,
  ) async {
    final carsSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .get();

    List<Map<String, dynamic>> allServices = [];

    for (var carDoc in carsSnap.docs) {
      final car = CarModel.fromMap(carDoc.data(), carDoc.id);

      final serviceSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(car.id)
          .collection('services')
          .orderBy('date', descending: true)
          .get();

      if (serviceSnap.docs.isEmpty) continue;

      for (var serviceDoc in serviceSnap.docs) {
        final service = ServiceModel.fromMap(serviceDoc.data(), serviceDoc.id);
        allServices.add({'car': car, 'service': service});
      }
    }

    allServices.sort((a, b) {
      final DateTime dateA = a['service'].date;
      final DateTime dateB = b['service'].date;
      return dateB.compareTo(dateA);
    });

    return allServices.take(2).toList();
  }

  // CRUD operacije za servise
  Future<DocumentReference> addService(
    String userId,
    String carId,
    ServiceModel service,
  ) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc();

    await ref.set(service.copyWith(id: ref.id).toMap());
    return ref;
  }

  Future<void> updateService(
    String userId,
    String carId,
    String serviceId,
    ServiceModel service,
  ) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId);
    await ref.set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteService(
    String userId,
    String carId,
    String serviceId,
  ) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId);
    await ref.delete();
  }
}
