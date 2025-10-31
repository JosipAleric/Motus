import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/refuel_model.dart';
import '../../../models/pagination_result.dart';
import '../../../core/pagination/pagination_notifier.dart';
import 'refuel_provider.dart';

class RefuelsPaginator extends PaginationNotifier<RefuelModel> {
  final Ref ref;
  final String carId;

  RefuelsPaginator(this.ref, this.carId, {int pageSize = 2})
      : super(pageSize: pageSize);

  @override
  Future<(List<RefuelModel>, QueryDocumentSnapshot<Map<String, dynamic>>?, bool)>
  fetchPage({
    required int pageIndex,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final refuelService = ref.read(refuelServiceProvider);

    if (refuelService == null) {
      return (<RefuelModel>[], null, false);
    }

    try {
      final PaginationResult<RefuelModel> result =
      await refuelService.getRefuelsPage(
        carId,
        pageSize: pageSize,
        startAfter: startAfter,
      );

      return (result.items, result.lastDocument, result.hasMore);
    } catch (e) {
      print("Greška pri paginaciji refuela: $e");
      return (<RefuelModel>[], null, false);
    }
  }
}
