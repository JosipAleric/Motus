import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motus/models/refuel_car_model.dart';
import '../models/car_model.dart';
import '../models/refuel_model.dart';
import '../models/refuel_statistics_model.dart';
import '../models/pagination_result.dart';

class RefuelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId;

  RefuelService(this._userId);

  CollectionReference<Map<String, dynamic>> _refuelsRef(String carId) {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('refuels');
  }

  Future<PaginationResult<RefuelModel>> getRefuelsPage(
      String carId, {
        int pageSize = 10,
        QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
      }) async {
    Query<Map<String, dynamic>> q = _refuelsRef(carId)
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snapshot = await q.get();
    final items = snapshot.docs.map((d) => RefuelModel.fromMap(d)).toList();

    bool hasMore = false;
    try{
      final nextPage = await q.startAfterDocument(snapshot.docs.last).get();
      if(nextPage.docs.isNotEmpty){
        hasMore = true;
      } else {
        hasMore = false;
      }
    }
    catch(e){
      print(e);
    }

    return PaginationResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: hasMore,
    );
  }

  Future<List<RefuelModel>> getRefuels(String carId) async {
    final snapshot =
    await _refuelsRef(carId).orderBy('date', descending: true).get();
    return snapshot.docs.map((d) => RefuelModel.fromMap(d)).toList();
  }

  Future<RefuelCar?> getRefuelDetailsById({required String carId, required String refuelId}) async {
    final refuelDoc = await _refuelsRef(carId).doc(refuelId).get();

    if (!refuelDoc.exists) {
      return null;
    }

    final refuel = RefuelModel.fromMap(refuelDoc);

    final carDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .get();

    if (!carDoc.exists) {
      throw Exception("Auto ne postoji");
    }

    final car = CarModel.fromMap(carDoc.data()!, carDoc.id);

    return RefuelCar(refuel: refuel, car: car);

  }

  Future<RefuelStatistics?> getRefuelStatistics(String carId) async {
    final snapshot = await _refuelsRef(carId)
        .orderBy('mileageAtRefuel', descending: false)
        .get();

    final refuels = snapshot.docs.map((d) => RefuelModel.fromMap(d)).toList();
    final totalRefuels = refuels.length;

    if (totalRefuels < 1) {
      return RefuelStatistics(
        averageConsumption: 0.0,
        totalCost: 0.0,
        averageCostPerRefuel: 0.0,
        totalRefuels: 0,
      );
    }

    double totalCost = 0.0;
    double totalFuelAmount = 0.0;
    for (var refuel in refuels) {
      totalCost += refuel.price;
      totalFuelAmount += refuel.liters;
    }

    final startMileage = refuels.first.mileageAtRefuel.toDouble();
    final endMileage = refuels.last.mileageAtRefuel.toDouble();
    final totalDistance = endMileage - startMileage;

    final averageConsumption =
    (totalDistance > 0) ? (totalFuelAmount / totalDistance) * 100 : 0.0;

    final averageCostPerRefuel = totalCost / totalRefuels;

    return RefuelStatistics(
      averageConsumption: averageConsumption,
      totalCost: totalCost,
      averageCostPerRefuel: averageCostPerRefuel,
      totalRefuels: totalRefuels,
    );
  }

  // ----------------------------------------------------------------------
  // Streams
  // ----------------------------------------------------------------------

  Stream<List<RefuelModel>> getRefuelsStream(String carId) {
    return _refuelsRef(carId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => RefuelModel.fromMap(d)).toList());
  }

  Stream<RefuelStatistics?> getRefuelStatisticsStream(String carId) {
    return _refuelsRef(carId)
        .orderBy('mileageAtRefuel', descending: false)
        .snapshots()
        .map((s) {
      final refuels = s.docs.map((d) => RefuelModel.fromMap(d)).toList();
      final totalRefuels = refuels.length;

      if (totalRefuels < 1) {
        return RefuelStatistics(
          averageConsumption: 0.0,
          totalCost: 0.0,
          averageCostPerRefuel: 0.0,
          totalRefuels: 0,
        );
      }

      double totalCost = 0.0;
      double totalFuelAmount = 0.0;
      for (var r in refuels) {
        totalCost += r.price;
        totalFuelAmount += r.liters;
      }

      final startMileage = refuels.first.mileageAtRefuel.toDouble();
      final endMileage = refuels.last.mileageAtRefuel.toDouble();
      final totalDistance = endMileage - startMileage;

      final averageConsumption =
      (totalDistance > 0) ? (totalFuelAmount / totalDistance) * 100 : 0.0;

      final averageCostPerRefuel = totalCost / totalRefuels;

      return RefuelStatistics(
        averageConsumption: averageConsumption,
        totalCost: totalCost,
        averageCostPerRefuel: averageCostPerRefuel,
        totalRefuels: totalRefuels,
      );
    });
  }

  Future<Map<String, double>> getFuelSummaryForPeriod({
    required String carId,
    String period = 'month',
    int? year,
  }) async {
    final now = DateTime.now().toUtc();
    DateTime? startDate;
    DateTime? endDate;

    switch (period) {
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        endDate = now;
        break;

      case 'year':
        final selectedYear = year ?? now.year;
        startDate = DateTime(selectedYear, 1, 1);
        endDate = DateTime(selectedYear, 12, 31, 23, 59, 59);
        break;

      case 'all':
        startDate = null;
        endDate = null;
        break;

      default:
        throw ArgumentError('Nepoznat period: $period');
    }

    Query query = _refuelsRef(carId);

    if (startDate != null && endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('date', descending: false);

    final snapshot = await query.get();

    double totalCost = 0.0;
    double totalLiters = 0.0;

    for (var doc in snapshot.docs) {
      final refuel = RefuelModel.fromMap(doc);
      totalCost += refuel.price;
      totalLiters += refuel.liters;
    }

    return {
      'totalCost': totalCost,
      'totalLiters': totalLiters,
    };
  }





  // ----------------------------------------------------------------------
  // CRUD
  // ----------------------------------------------------------------------

  Future<void> addRefuel({required String carId, required RefuelModel refuel}) async {
    final refDoc = _refuelsRef(carId).doc();
    await refDoc.set(refuel.copyWith(id: refDoc.id).toMap());
  }

  Future<void> updateRefuel({required String carId, required RefuelModel refuel}) async {
    await _refuelsRef(carId).doc(refuel.id).update(refuel.toMap());
  }

  Future<void> deleteRefuel({required String carId, required String refuelId}) async {
    await _refuelsRef(carId).doc(refuelId).delete();
  }
}
