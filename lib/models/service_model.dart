import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String carId;
  final String type;
  final String service_notes;
  final double price;
  final DateTime date;
  final int mileage_at_service;
  final String service_center;
  final String? invoiceUrl;


  ServiceModel({
    required this.id,
    required this.carId,
    required this.type,
    required this.service_notes,
    required this.price,
    required this.date,
    required this.mileage_at_service,
    required this.service_center,
    this.invoiceUrl,
  });

  ServiceModel copyWith({
    String? id,
    String? carId,
    String? type,
    String? service_notes,
    double? price,
    DateTime? date,
    int? mileage_at_service,
    String? service_center,
    String? invoiceUrl,
  }) {
    return ServiceModel(
      carId: carId ?? this.carId,
      id: id ?? this.id,
      type: type ?? this.type,
      service_notes: service_notes ?? this.service_notes,
      price: price ?? this.price,
      date: date ?? this.date,
      mileage_at_service: mileage_at_service ?? this.mileage_at_service,
      service_center: service_center ?? this.service_center,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl
    );
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    final rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    final carId = map['carId'] ?? map['car_id'] ?? '';

    double price;
    if (map.containsKey('price')) {
      price = (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0;
    } else if (map.containsKey('cost')) {
      price = (map['cost'] is num) ? (map['cost'] as num).toDouble() : 0.0;
    } else {
      price = 0.0;
    }

    return ServiceModel(
      carId: carId,
      id: id,
      type: map['type'] ?? '',
      service_notes: map['service_notes'] ?? '',
      price: price,
      date: parsedDate,
      mileage_at_service: (map['mileage_at_service'] is int)
          ? map['mileage_at_service'] as int
          : (map['mileage_at_service'] is num)
              ? (map['mileage_at_service'] as num).toInt()
              : 0,
      service_center: map['service_center'] ?? '',
      invoiceUrl: map['invoiceUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'type': type,
      'service_notes': service_notes,
      'price': price,
      'date': date.toIso8601String(),
      'mileage_at_service': mileage_at_service,
      'service_center': service_center,
      'invoiceUrl': invoiceUrl,
    };
  }
}