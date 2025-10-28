import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/refuel_model.dart';
import 'dart:math';

// 📊 Model za statistiku (ostaje isti)
class RefuelStatistics {
  final double averageConsumption;
  final double totalCost;
  final double averageCostPerRefuel;
  final int totalRefuels;

  RefuelStatistics({
    required this.averageConsumption,
    required this.totalCost,
    required this.averageCostPerRefuel,
    required this.totalRefuels,
  });

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  String toString() {
    return 'RefuelStatistics(\n'
        '  Prosječna potrošnja: ${_round(averageConsumption)} L/100km,\n'
        '  Ukupno Potrošeno novca: ${_round(totalCost)} BAM,\n'
        '  Prosječna cijena: ${_round(averageCostPerRefuel)},\n'
        '  Ukupno točenja: $totalRefuels\n'
        ')';
  }
}

class RefuelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _refuelsRef(String userId, String carId) {
    return _db.collection('users').doc(userId).collection('cars').doc(carId).collection('refuels');
  }

  Stream<List<RefuelModel>> getRefuels(String userId, String carId) {
    return _refuelsRef(userId, carId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => RefuelModel.fromMap(doc)).toList());
  }

  Stream<RefuelStatistics?> getRefuelStatistics(String userId, String carId) {
    // Dohvaćamo refuele, sortirane po kilometraži (za lako određivanje početne i krajnje KM)
    return _refuelsRef(userId, carId)
        .orderBy('mileageAtRefuel', descending: false) // Sortiramo uzlazno po KM
        .snapshots()
        .map((snapshot) {
      final List<RefuelModel> refuels =
      snapshot.docs.map((doc) => RefuelModel.fromMap(doc)).toList();

      final int totalRefuels = refuels.length;

      if (totalRefuels < 1) {
        // Vraćamo 0 za sve, uključujući totalCost
        return RefuelStatistics(
          averageConsumption: 0.0,
          totalCost: 0.0,
          averageCostPerRefuel: 0.0,
          totalRefuels: 0,
        );
      }

      // --- Izračunavanje Statistike ---

      // 1. Ukupni trošak i Ukupna količina goriva
      double totalCost = 0.0;
      double totalFuelAmount = 0.0;
      for (var refuel in refuels) {
        totalCost += refuel.price; // Polje 'price' u RefuelModel-u je ukupna cijena točenja
        totalFuelAmount += refuel.liters;
      }

      // 2. Ukupno pređeni kilometri
      // Svi refueli su sortirani uzlazno po mileage-u
      final double startMileage = refuels.first.mileageAtRefuel.toDouble();
      final double endMileage = refuels.last.mileageAtRefuel.toDouble();
      final double totalDistance = endMileage - startMileage;


      // 🔹 PROSJEČNA POTROŠNJA (dugoročna)
      final double averageConsumption = (totalDistance > 0)
          ? (totalFuelAmount / totalDistance) * 100.0
          : 0.0;

      // 🔹 PROSJEČNA CIJENA PO TOČENJU
      final double averageCostPerRefuel = totalCost / totalRefuels;

      // 🔹 UKUPNA CIJENA SVIH TOČENJA
      // Vrijednost je već izračunata kao totalCost

      return RefuelStatistics(
        averageConsumption: averageConsumption,
        totalCost: totalCost, // Ovdje šaljemo totalCost
        averageCostPerRefuel: averageCostPerRefuel,
        totalRefuels: totalRefuels,
      );
    });
  }

  // Ostatak RefuelService metode...
  // ... (addRefuel, updateRefuel, deleteRefuel ostaju nepromijenjene) ...

  // 🔹 Dodaj novi refuel
  Future<void> addRefuel(String userId, String carId, RefuelModel refuel) async {
    final ref = _refuelsRef(userId, carId).doc();
    // Napomena: copyWith se koristi ako želite dodijeliti ID
    await ref.set(refuel.copyWith(id: ref.id).toMap());
  }

  // 🔹 Ažuriraj postojeći refuel
  Future<void> updateRefuel(String userId, String carId, RefuelModel refuel) async {
    await _refuelsRef(userId, carId).doc(refuel.id).update(refuel.toMap());
  }

  // 🔹 Obriši refuel
  Future<void> deleteRefuel(String userId, String carId, String refuelId) async {
    await _refuelsRef(userId, carId).doc(refuelId).delete();
  }
}