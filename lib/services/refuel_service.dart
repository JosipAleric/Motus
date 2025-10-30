import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/refuel_model.dart';
import '../models/refuel_statistics_model.dart';
import '../models/pagination_result.dart';
import '../providers/user_provider.dart';

class RefuelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Ref ref;

  RefuelService(this.ref);

  /// ✅ Dohvati userId iz Riverpoda
  String get _userId {
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) throw Exception("Korisnik nije prijavljen.");
    return authUser.uid;
  }

  /// ✅ Kolekcija refuela
  CollectionReference<Map<String, dynamic>> _refuelsRef(String carId) {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('cars')
        .doc(carId)
        .collection('refuels');
  }

  // 🔹 Paginated fetch
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

    return PaginationResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  // 🔹 Svi refueli
  Future<List<RefuelModel>> getRefuels(String carId) async {
    final snapshot = await _refuelsRef(carId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((d) => RefuelModel.fromMap(d)).toList();
  }

  // 🔹 Statistika
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

  // 🔹 Stream refuela
  Stream<List<RefuelModel>> getRefuelsStream(String carId) {
    return _refuelsRef(carId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => RefuelModel.fromMap(d)).toList());
  }

  // 🔹 Stream statistike
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

  // 🔹 CRUD
  Future<void> addRefuel(String carId, RefuelModel refuel) async {
    final refDoc = _refuelsRef(carId).doc();
    await refDoc.set(refuel.copyWith(id: refDoc.id).toMap());
  }

  Future<void> updateRefuel(String carId, RefuelModel refuel) async {
    await _refuelsRef(carId).doc(refuel.id).update(refuel.toMap());
  }

  Future<void> deleteRefuel(String carId, String refuelId) async {
    await _refuelsRef(carId).doc(refuelId).delete();
  }
}
