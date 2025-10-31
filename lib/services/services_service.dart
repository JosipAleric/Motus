import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motus/providers/car_provider.dart';
import '../models/car_model.dart';
import '../models/service_car_model.dart';
import '../models/service_model.dart';
import '../models/pagination_result.dart';

class ServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId;

  ServicesService(this._userId);

  // Reference to services collection for a specific car
  CollectionReference<Map<String, dynamic>> _serviceCollection(String carId) {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('services');
  }

  // Fetch car by ID
  Future<CarModel> _getCar(String carId) async {
    final doc = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();

    if (!doc.exists) throw Exception("Auto ne postoji");
    return CarModel.fromMap(doc.data()!, doc.id);
  }

  // Paination for services of a specific car
  Future<PaginationResult<ServiceCar>> getServicesForCarPage(
      String carId, {
        int pageSize = 4,
        QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
      }) async {
    final car = await _getCar(carId);

    Query<Map<String, dynamic>> q = _serviceCollection(carId)
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snapshot = await q.get();

    final items = snapshot.docs.map((d) {
      final service = ServiceModel.fromMap(d.data(), d.id);
      return ServiceCar(service: service, car: car);
    }).toList();

    return PaginationResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }


  Stream<List<ServiceCar>> getServicesForCarStream(String carId) {
    final carFuture = _getCar(carId);

    return _serviceCollection(carId)
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final car = await carFuture;
      return snapshot.docs
          .map((d) => ServiceModel.fromMap(d.data(), d.id))
          .map((s) => ServiceCar(service: s, car: car))
          .toList();
    });
  }

  Future<List<ServiceCar>> getServicesForCar(String carId) async {
    final car = await _getCar(carId);
    final snapshot = await _serviceCollection(carId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((d) {
      final service = ServiceModel.fromMap(d.data(), d.id);
      return ServiceCar(service: service, car: car);
    }).toList();
  }


  // Service details
  Future<ServiceCar?> getServiceWithCar(String carId, String serviceId) async {
    final doc = await _serviceCollection(carId).doc(serviceId).get();

    if (!doc.exists) return null;

    final car = await _getCar(carId);
    final service = ServiceModel.fromMap(doc.data()!, doc.id);

    return ServiceCar(service: service, car: car);
  }

  // ----------------------------------------------------------------------
  // Latest services
  // ----------------------------------------------------------------------

  Future<Map<String, dynamic>?> getLastServiceForCar(String carId) async {
    final carSnap = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();

    if (!carSnap.exists) return null;
    final car = CarModel.fromMap(carSnap.data()!, carSnap.id);

    final serviceSnap = await _serviceCollection(carId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (serviceSnap.docs.isEmpty) return null;

    final serviceDoc = serviceSnap.docs.first;
    final service = ServiceModel.fromMap(serviceDoc.data(), serviceDoc.id);

    return {'car': car, 'service': service};
  }

  Future<List<Map<String, dynamic>>> getLatestServicesWithCar() async {
    final carsSnap = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .get();

    List<Map<String, dynamic>> all = [];

    for (var c in carsSnap.docs) {
      final car = CarModel.fromMap(c.data(), c.id);

      final servicesSnap = await _serviceCollection(car.id)
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      for (var s in servicesSnap.docs) {
        final service = ServiceModel.fromMap(s.data(), s.id);
        all.add({'car': car, 'service': service});
      }
    }

    all.sort((a, b) =>
        (b['service'].date as DateTime).compareTo(a['service'].date));

    return all.take(2).toList();
  }

  // ----------------------------------------------------------------------
  //  CRUD
  // ----------------------------------------------------------------------

  Future<DocumentReference<Map<String, dynamic>>> addService(String carId, ServiceModel service) async {
    final ref = _serviceCollection(carId).doc();
    final serviceWithId = service.copyWith(id: ref.id);

    await ref.set(serviceWithId.toMap());
    return ref;
  }

  Future<void> updateService(
      String carId,
      String serviceId,
      ServiceModel service,
      ) async {
    final ref = _serviceCollection(carId).doc(serviceId);
    await ref.set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteService(String carId, String serviceId) async {
    final ref = _serviceCollection(carId).doc(serviceId);
    await ref.delete();
  }
}
