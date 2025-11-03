import 'package:motus/models/refuel_model.dart';
import 'car_model.dart';

class RefuelCar {
  final CarModel car;
  final RefuelModel refuel;

  RefuelCar({
    required this.car,
    required this.refuel,
  });
}