import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motus/providers/refuel/refuel_provider.dart';
import '../../../models/refuel_model.dart';
import '../../../models/pagination_result.dart';
import '../user_provider.dart';
import '../../../core/pagination/pagination_notifier.dart';

class RefuelsPaginator extends PaginationNotifier<RefuelModel> {
  final Ref ref;
  final String carId;

  RefuelsPaginator(this.ref, this.carId) : super(pageSize: 3);

  @override
  Future<(List<RefuelModel>, QueryDocumentSnapshot<Map<String, dynamic>>?, bool)>
  fetchPage({
    required int pageIndex,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {

    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) return (<RefuelModel>[], null, false);

    final refuels = ref.read(refuelServiceProvider);

    final PaginationResult<RefuelModel> result = await refuels.getRefuelsPage(
      carId,
      pageSize: pageSize,
      startAfter: startAfter,
    );

    return (result.items, result.lastDocument, result.hasMore);
  }
}
