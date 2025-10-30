import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pagination_state.dart';

abstract class PaginationNotifier<T> extends StateNotifier<PaginationState<T>> {
  PaginationNotifier({this.pageSize = 10})
      : super(PaginationState<T>.initial());

  final int pageSize;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageCursors = [];

  Future<(List<T> items, QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc, bool hasMore)>
  fetchPage({
    required int pageIndex,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  });

  Future<void> loadPage(int pageIndex) async {
    state = state.copyWith(isLoading: true);

    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter;

    if (pageIndex > 0 && pageIndex <= _pageCursors.length) {
      startAfter = _pageCursors[pageIndex - 1];
    }

    final (items, lastDoc, hasMore) =
    await fetchPage(pageIndex: pageIndex, startAfter: startAfter);

    if (pageIndex == _pageCursors.length && lastDoc != null) {
      _pageCursors.add(lastDoc);
    }

    state = state.copyWith(
      items: items,
      isLoading: false,
      hasMore: hasMore,
      pageIndex: pageIndex,
    );
  }

  Future<void> next() async {
    if (!state.hasMore) return;
    await loadPage(state.pageIndex + 1);
  }

  Future<void> prev() async {
    if (state.pageIndex == 0) return;
    await loadPage(state.pageIndex - 1);
  }

  void reset() {
    _pageCursors.clear();
    state = PaginationState<T>.initial();
  }
}
