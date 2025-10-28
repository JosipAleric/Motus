import 'package:cloud_firestore/cloud_firestore.dart';

class RefuelModel {
  final String id;
  final DateTime date;
  final num mileageAtRefuel;       // kilometraža prilikom točenja
  final double liters;         // količina točenog goriva u litrama
  final double pricePerLiter;  // cijena po litri
  final double price;      // ukupan trošak (liters * pricePerLiter)
  final bool usedFuelAditives;
  final String? gasStation;    // opcionalno: ime benzinske
  final String? notes;         // dodatne napomene
  final String carId;          // referenca na auto

  RefuelModel({
    required this.id,
    required this.date,
    required this.mileageAtRefuel,
    required this.liters,
    required this.pricePerLiter,
    required this.price,
    required this.usedFuelAditives,
    required this.carId,
    this.gasStation,
    this.notes,
  });

  // 🔹 Pretvaranje Firestore dokumenta u objekt
  factory RefuelModel.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RefuelModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      mileageAtRefuel: (data['mileageAtRefuel'] as num),
      liters: (data['liters'] as num).toDouble(),
      pricePerLiter: (data['pricePerLiter'] as num).toDouble(),
      price: (data['price'] as num).toDouble(),
      usedFuelAditives: data['usedFuelAditives'] ?? false,
      gasStation: data['gasStation'],
      notes: data['notes'],
      carId: data['carId'],
    );
  }

  // 🔹 Pretvaranje objekta u Map za Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'mileageAtRefuel': mileageAtRefuel,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'price': price,
      'usedFuelAditives': usedFuelAditives,
      'gasStation': gasStation,
      'notes': notes,
      'carId': carId,
    };
  }

  // 🔹 Kopija s izmjenama (korisno za update)
  RefuelModel copyWith({
    String? id,
    DateTime? date,
    double? mileageAtRefuel,
    double? liters,
    double? pricePerLiter,
    double? price,
    bool? usedFuelAditives,
    String? gasStation,
    String? notes,
    String? carId,
  }) {
    return RefuelModel(
      id: id ?? this.id,
      date: date ?? this.date,
      mileageAtRefuel: mileageAtRefuel ?? this.mileageAtRefuel,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      price: price ?? this.price,
      usedFuelAditives: usedFuelAditives ?? this.usedFuelAditives,
      gasStation: gasStation ?? this.gasStation,
      notes: notes ?? this.notes,
      carId: carId ?? this.carId,
    );
  }

}
