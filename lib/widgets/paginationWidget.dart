import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motus/widgets/customAlert.dart';
import '../core/pagination/pagination_state.dart';
import '../core/pagination/pagination_notifier.dart';

/// Generic Pagination Widget
/// T = model tip (RefuelModel, ServiceCar, itd.)
class PaginationWidget<T> extends ConsumerWidget {
  final PaginationState<T> state;
  final PaginationNotifier<T> notifier;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final bool outerScrollable;

  const PaginationWidget({
    super.key,
    required this.state,
    required this.notifier,
    required this.itemBuilder,
    this.emptyMessage = "No items found",
    this.outerScrollable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Padding(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.items.isEmpty) {
      if (state.isLoading) return const Center(child: CircularProgressIndicator());
      return Center(child: CustomAlert(type: AlertType.info, title: "Obavijest", message: "$emptyMessage"));
    }

    if (outerScrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...state.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: itemBuilder(context, item),
          )).toList(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _buildPaginationControls(notifier, state),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          return itemBuilder(context, state.items[index]);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _buildPaginationControls(notifier, state),
          );
        }
      },
    );
  }

  Widget _buildPaginationControls(PaginationNotifier<T> notifier, PaginationState<T> state) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageButton(
          label: '<',
          disabled: state.pageIndex == 0,
          onTap: state.pageIndex > 0 ? () => notifier.prev() : null,
        ),
        const SizedBox(width: 12),
        Text('Trenutna stranica: ${state.pageIndex + 1}'),
        const SizedBox(width: 12),
        _buildPageButton(
          label: '>',
          disabled: !state.hasMore,
          onTap: state.hasMore ? () => notifier.next() : null,
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required String label,
    required bool disabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? Colors.grey.shade200 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: disabled ? Colors.grey.shade400 : Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}