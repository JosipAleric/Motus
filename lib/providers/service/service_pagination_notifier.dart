import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/service_car_model.dart';
import '../../../models/pagination_result.dart';
import '../../../core/pagination/pagination_notifier.dart';
import 'service_provider.dart';

class ServicesPaginator extends PaginationNotifier<ServiceCar> {
  final Ref ref;
  final String carId;

  ServicesPaginator(this.ref, this.carId, {int pageSize = 5})
      : super(pageSize: pageSize);

  @override
  Future<(List<ServiceCar>, QueryDocumentSnapshot<Map<String, dynamic>>?, bool)>
  fetchPage({
    required int pageIndex,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      final servicesService = ref.read(serviceProvider);

      final PaginationResult<ServiceCar> result =
      await servicesService.getServicesForCarPage(
        carId,
        pageSize: pageSize,
        startAfter: startAfter,
      );

      return (result.items, result.lastDocument, result.hasMore);
    } catch (e) {
      // Ako nešto pođe po zlu, vrati prazan rezultat
      print("Greška pri paginaciji servisa: $e");
      return (<ServiceCar>[], null, false);
    }
  }
}
