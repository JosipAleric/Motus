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
  final String VIN;
  final String? imageUrl;

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
    required this.VIN,
    this.imageUrl,
  });

  CarModel copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? fuel_type,
    String? transmission,
    double? displacement, // Corrected type
    String? drive_type,
    int? horsepower,
    String? license_plate,
    int? mileage,
    String? VIN,
    String? imageUrl,
  }) {
    return CarModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuel_type: fuel_type ?? this.fuel_type,
      transmission: transmission ?? this.transmission,
      displacement: displacement ?? this.displacement, // Fixed
      drive_type: drive_type ?? this.drive_type,
      horsepower: horsepower ?? this.horsepower,
      license_plate: license_plate ?? this.license_plate,
      mileage: mileage ?? this.mileage,
      VIN: VIN ?? this.VIN,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuel_type,
      'transmission': transmission,
      'displacement': displacement,
      'drive_type': drive_type,
      'horsepower': horsepower,
      'license_plate': license_plate,
      'mileage': mileage,
      'VIN': VIN,
      'imageUrl': imageUrl,
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] is int ? map['year'] : int.tryParse(map['year'].toString()) ?? 0,
      fuel_type: map['fuel_type'] ?? '',
      transmission: map['transmission'] ?? '',
      drive_type: map['drive_type'] ?? '',
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
      VIN: map['VIN'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}
