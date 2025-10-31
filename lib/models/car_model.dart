class CarModel {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String fuel_type;
  final String transmission;
  final double displacement;
  final String drive_type;
  final int horsepower;
  final String license_plate;
  final int mileage;
  final String vin;
  final String? imageUrl;
  final String vehicle_type;

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel_type,
    required this.transmission,
    required this.displacement,
    required this.drive_type,
    required this.horsepower,
    required this.license_plate,
    required this.mileage,
    required this.vin,
    required this.vehicle_type,
    this.imageUrl,
  });

  // 🔁 MAPIRANJA
  static const Map<String, String> fuelTypeToEng = {
    'Benzin': 'petrol',
    'Dizel': 'diesel',
    'Električni': 'electric',
    'Hibrid': 'hybrid',
  };

  static const Map<String, String> fuelTypeFromEng = {
    'petrol': 'Benzin',
    'diesel': 'Dizel',
    'electric': 'Električni',
    'hybrid': 'Hibrid',
  };

  static const Map<String, String> transmissionToEng = {
    'Automatski': 'automatic',
    'Manualni': 'manual',
  };

  static const Map<String, String> transmissionFromEng = {
    'automatic': 'Automatski',
    'manual': 'Manualni',
  };

  static const Map<String, String> driveTypeToEng = {
    'Prednji pogon': 'front',
    'Zadnji pogon': 'rear',
    '4x4': 'awd',
  };

  static const Map<String, String> driveTypeFromEng = {
    'front': 'Prednji pogon',
    'rear': 'Zadnji pogon',
    'awd': '4x4',
  };

  CarModel copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? fuel_type,
    String? transmission,
    double? displacement,
    String? drive_type,
    int? horsepower,
    String? license_plate,
    int? mileage,
    String? vin,
    String? vehicle_type,
    String? imageUrl,
  }) {
    return CarModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuel_type: fuel_type ?? this.fuel_type,
      transmission: transmission ?? this.transmission,
      displacement: displacement ?? this.displacement,
      drive_type: drive_type ?? this.drive_type,
      horsepower: horsepower ?? this.horsepower,
      license_plate: license_plate ?? this.license_plate,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      vehicle_type: vehicle_type ?? this.vehicle_type,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // ✅ Kad se sprema u Firestore – koristi engleske vrijednosti
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelTypeToEng[fuel_type] ?? fuel_type,
      'transmission': transmissionToEng[transmission] ?? transmission,
      'drive_type': driveTypeToEng[drive_type] ?? drive_type,
      'displacement': displacement,
      'horsepower': horsepower,
      'license_plate': license_plate,
      'mileage': mileage,
      'vin': vin,
      'imageUrl': imageUrl,
      'vehicle_type': vehicle_type,
    };
  }

  // ✅ Kad se učitava iz Firestore – pretvori natrag u hrvatski
  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] is int
          ? map['year']
          : int.tryParse(map['year'].toString()) ?? 0,
      fuel_type: fuelTypeFromEng[map['fuel_type']] ?? map['fuel_type'] ?? '',
      transmission:
      transmissionFromEng[map['transmission']] ?? map['transmission'] ?? '',
      drive_type: driveTypeFromEng[map['drive_type']] ?? map['drive_type'] ?? '',
      displacement: map['displacement'] is double
          ? map['displacement']
          : double.tryParse(map['displacement'].toString()) ?? 0.0,
      horsepower: map['horsepower'] is int
          ? map['horsepower']
          : int.tryParse(map['horsepower'].toString()) ?? 0,
      license_plate: map['license_plate'] ?? '',
      mileage: map['mileage'] is int
          ? map['mileage']
          : int.tryParse(map['mileage'].toString()) ?? 0,
      vin: map['vin'] ?? '',
      imageUrl: map['imageUrl'],
      vehicle_type: map['vehicle_type'] ?? '',
    );
  }
}
