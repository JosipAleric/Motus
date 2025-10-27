class RefuelModel {
  final String id;
  final DateTime date;
  final double liters;
  final double totalCost;
  final double mileageAtRefuel;

  RefuelModel({
    required this.id,
    required this.date,
    required this.liters,
    required this.totalCost,
    required this.mileageAtRefuel,
  });

  RefuelModel copyWith({
    String? id,
    DateTime? date,
    double? liters,
    double? totalCost,
    double? mileageAtRefuel,
  }) {
    return RefuelModel(
      id: id ?? this.id,
      date: date ?? this.date,
      liters: liters ?? this.liters,
      totalCost: totalCost ?? this.totalCost,
      mileageAtRefuel: mileageAtRefuel ?? this.mileageAtRefuel,
    );
  }

  factory RefuelModel.fromMap(Map<String, dynamic> map, String id) {
    return RefuelModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      liters: map['liters'],
      totalCost: map['totalCost'],
      mileageAtRefuel: map['mileageAtRefuel'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'liters': liters,
      'totalCost': totalCost,
      'mileageAtRefuel': mileageAtRefuel,
    };
  }
}