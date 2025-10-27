import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';

class ServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;



// Glavna funkcija koja spaja servise i automobil
  Stream<List<ServiceCar>> getServicesForCar(String userId, String carId) {

    final Future<CarModel> carDetailsFuture = _getCarDetails(userId, carId);

    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .snapshots()
    // Transformacija streama dokumenata u List<ServiceModel>
        .map((snapshot) => snapshot.docs
    // Pretpostavljamo da ServiceModel.fromMap prima (data, id)
        .map((d) => ServiceModel.fromMap(d.data(), d.id))
        .toList()
    )
    // 3. Spajanje ServiceModel liste s CarModel-om
    // Koristimo asyncMap za asinkronu transformaciju elemenata streama
        .asyncMap((serviceList) async {

      // Čekamo da Future za automobil vrati objekt CarModel
      final CarModel car = await carDetailsFuture;

      // Kreiramo List<ServiceCar> koristeći dohvaćeni CarModel
      return serviceList.map((service) {
        return ServiceCar(
          service: service,
          car: car, // Dodajemo isti objekt automobila svakom servisu
        );
      }).toList();
    });
  }

  // Stream<List<ServiceModel>> getServicesForCar(String userId, String carId) {
  //   return _db
  //       .collection('users')
  //       .doc(userId)
  //       .collection('cars')
  //       .doc(carId)
  //       .collection('services')
  //       .orderBy('date', descending: true)
  //       .snapshots()
  //       .map(
  //         (snapshot) => snapshot.docs
  //         .map((d) => ServiceModel.fromMap(d.data(), d.id))
  //         .toList(),
  //   );
  // }

  Future<CarModel> _getCarDetails(String userId, String carId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .get();

      return CarModel.fromMap(doc.data()!, doc.id);

  }

  Future<ServiceCar?> getServiceWithCar(String userId, String carId, String serviceId) async {
    // Dohvati dokument servisa direktno
    final serviceDoc = await _db
        .collection('users').doc(userId).collection('cars').doc(carId)
        .collection('services').doc(serviceId).get();

    if (!serviceDoc.exists) return null;

    final serviceData = serviceDoc.data()!;

    // Asinkrono dohvati detalje o automobilu
    final car = await _getCarDetails(userId, carId);

    // Vrati ServiceCar objekt
    return ServiceCar(
      service: ServiceModel.fromMap(serviceData, serviceDoc.id),
      car: car,
    );
  }



  Future<Map<String, dynamic>?> getLastServiceWithCar(String userId) async {
    final carsSnap = await _db.collection('users').doc(userId).collection('cars').get();

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
        latestServiceData = {
          'car': car,
          'service': service,
        };
      }
    }

    return latestServiceData;
  }

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