import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

    Query<Map<String, dynamic>> q = _serviceCollection(
      carId,
    ).orderBy('date', descending: true).limit(pageSize);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snapshot = await q.get();

    final items = snapshot.docs.map((d) {
      final service = ServiceModel.fromMap(d.data(), d.id);
      return ServiceCar(service: service, car: car);
    }).toList();

    bool hasMore = false;
    try {
      final nextPage = await q.startAfterDocument(snapshot.docs.last).get();
      if (nextPage.docs.isNotEmpty) {
        hasMore = true;
      } else {
        hasMore = false;
      }
    } catch (e) {
      print(e);
    }

    return PaginationResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: hasMore,
    );
  }

  Stream<List<ServiceCar>> getServicesForCarStream(String carId) {
    final carFuture = _getCar(carId);

    return _serviceCollection(
      carId,
    ).orderBy('date', descending: true).snapshots().asyncMap((snapshot) async {
      final car = await carFuture;
      return snapshot.docs
          .map((d) => ServiceModel.fromMap(d.data(), d.id))
          .map((s) => ServiceCar(service: s, car: car))
          .toList();
    });
  }

  Future<List<ServiceCar>> getServicesForCar(String carId) async {
    final car = await _getCar(carId);
    final snapshot = await _serviceCollection(
      carId,
    ).orderBy('date', descending: true).get();

    return snapshot.docs.map((d) {
      final service = ServiceModel.fromMap(d.data(), d.id);
      return ServiceCar(service: service, car: car);
    }).toList();
  }

  // Service details
  Future<ServiceCar?> getServiceWithCar({
    required String carId,
    required String serviceId,
  }) async {
    final doc = await _serviceCollection(carId).doc(serviceId).get();

    if (!doc.exists) return null;

    final car = await _getCar(carId);
    final service = ServiceModel.fromMap(doc.data()!, doc.id);

    return ServiceCar(service: service, car: car);
  }

  // Latest services
  Future<Map<String, dynamic>?> getLastServiceForCar(String carId) async {
    final carSnap = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();

    if (!carSnap.exists) return null;
    final car = CarModel.fromMap(carSnap.data()!, carSnap.id);

    final serviceSnap = await _serviceCollection(
      carId,
    ).orderBy('date', descending: true).limit(1).get();

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

      final servicesSnap = await _serviceCollection(
        car.id,
      ).orderBy('date', descending: true).limit(2).get();

      for (var s in servicesSnap.docs) {
        final service = ServiceModel.fromMap(s.data(), s.id);
        all.add({'car': car, 'service': service});
      }
    }

    all.sort(
      (a, b) => (b['service'].date as DateTime).compareTo(a['service'].date),
    );

    return all.take(2).toList();
  }

  // Service statistics
  Future<Map<String, dynamic>> getServiceStats({
    required String carId,
    required String period, // 'all', 'month', 'year'
    int? year,
  }) async {
    DateTime? startDate;
    DateTime? endDate;
    final now = DateTime.now();

    if (period == 'month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (period == 'year' && year != null) {
      startDate = DateTime(year, 1, 1);
      endDate = DateTime(year, 12, 31, 23, 59, 59);
    }

    Query<Map<String, dynamic>> query = _serviceCollection(carId);

    if (startDate != null && endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('date', descending: false);
    final snapshot = await query.get();

    double totalCost = 0.0;
    int totalServices = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final cost = (data['price'] ?? 0) as num;

      totalCost += cost.toDouble();
      totalServices += 1;
    }

    return {'totalCost': totalCost, 'totalServices': totalServices};
  }

  //  CRUD
  Future<DocumentReference<Map<String, dynamic>>> addService(
    String carId,
    ServiceModel service,
  ) async {
    final serviceRef = _serviceCollection(carId).doc();
    final serviceWithId = service.copyWith(id: serviceRef.id);

    final currency = await serviceRef.set(serviceWithId.toMap());
    return serviceRef;
  }

  Future<void> updateService(ServiceModel service) async {
    final ref = _serviceCollection(service.carId).doc(service.id);
    await ref.set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteService({
    required String carId,
    required String serviceId,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$_userId/cars/$carId/services/$serviceId/invoice.jpg',
      );

      await storageRef.delete().catchError((_) {
        print('Nema slike za brisanje.');
      });

      await _serviceCollection(carId).doc(serviceId).delete();
    } catch (e) {
      print('Greška pri brisanju servisa: $e');
    }
  }
}
