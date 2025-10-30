class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int pageIndex;

  PaginationState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.pageIndex,
  });

  factory PaginationState.initial() => PaginationState(
    items: [],
    isLoading: false,
    hasMore: false,
    pageIndex: 0,
  );

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    int? pageIndex,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}
