import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';
import '../models/pagination_result.dart';
import '../providers/user_provider.dart';

class ServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Ref ref;

  ServicesService(this.ref);

  /// ✅ Pomoćna funkcija za dohvat trenutnog userId
  String get _userId {
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) {
      throw Exception("Korisnik nije prijavljen.");
    }
    return authUser.uid;
  }

  /// ✅ Dohvati detalje o autu
  Future<CarModel> _getCarDetails(String carId) async {
    final doc = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();
    return CarModel.fromMap(doc.data()!, doc.id);
  }

  /// ✅ Paginated fetch servisa
  Future<PaginationResult<ServiceCar>> getServicesForCarPage(
      String carId, {
        int pageSize = 10,
        QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
      }) async {
    final car = await _getCarDetails(carId);

    Query<Map<String, dynamic>> q = _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snapshot = await q.get();
    final items = snapshot.docs
        .map((d) => ServiceModel.fromMap(d.data(), d.id))
        .map((service) => ServiceCar(service: service, car: car))
        .toList();

    return PaginationResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// ✅ Stream servisa za auto
  Stream<List<ServiceCar>> getServicesForCarStream(String carId) {
    final carFuture = _getCarDetails(carId);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final car = await carFuture;
      final services = snapshot.docs
          .map((d) => ServiceModel.fromMap(d.data(), d.id))
          .toList();
      return services.map((s) => ServiceCar(service: s, car: car)).toList();
    });
  }

  /// ✅ Future verzija servisa
  Future<List<ServiceCar>> getServicesForCar(String carId) async {
    final car = await _getCarDetails(carId);
    final snapshot = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((d) => ServiceCar(
      service: ServiceModel.fromMap(d.data(), d.id),
      car: car,
    ))
        .toList();
  }

  /// ✅ Dohvati jedan servis s vozilom
  Future<ServiceCar?> getServiceWithCar(String carId, String serviceId) async {
    final serviceDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId)
        .get();

    if (!serviceDoc.exists) return null;

    final car = await _getCarDetails(carId);
    return ServiceCar(
      service: ServiceModel.fromMap(serviceDoc.data()!, serviceDoc.id),
      car: car,
    );
  }

  /// ✅ Zadnji servis za auto
  Future<Map<String, dynamic>?> getLastServiceForCar(String carId) async {
    final carDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();

    if (!carDoc.exists) return null;

    final car = CarModel.fromMap(carDoc.data()!, carDoc.id);

    final serviceSnap = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(car.id)
        .collection('services')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (serviceSnap.docs.isEmpty) return null;

    final serviceDoc = serviceSnap.docs.first;
    final service = ServiceModel.fromMap(serviceDoc.data(), serviceDoc.id);

    return {'car': car, 'service': service};
  }

  /// ✅ Zadnji servisi s automobilima
  Future<List<Map<String, dynamic>>> getLatestServicesWithCar() async {
    final carsSnap = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .get();

    List<Map<String, dynamic>> allServices = [];

    for (var carDoc in carsSnap.docs) {
      final car = CarModel.fromMap(carDoc.data(), carDoc.id);
      final serviceSnap = await _db
          .collection('users')
          .doc(_userId)
          .collection('cars')
          .doc(car.id)
          .collection('services')
          .orderBy('date', descending: true)
          .get();

      for (var serviceDoc in serviceSnap.docs) {
        final service = ServiceModel.fromMap(serviceDoc.data(), serviceDoc.id);
        allServices.add({'car': car, 'service': service});
      }
    }

    allServices.sort((a, b) =>
        (b['service'].date as DateTime).compareTo(a['service'].date as DateTime));

    return allServices.take(2).toList();
  }

  /// ✅ CRUD
  Future<DocumentReference> addService(String carId, ServiceModel service) async {
    final ref = _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc();

    await ref.set(service.copyWith(id: ref.id).toMap());
    return ref;
  }

  Future<void> updateService(
      String carId, String serviceId, ServiceModel service) async {
    final ref = _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId);
    await ref.set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteService(String carId, String serviceId) async {
    final ref = _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services')
        .doc(serviceId);
    await ref.delete();
  }
}
