// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';

class PaginationResult<T> {
  final List<T> items;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  PaginationResult({required this.items, this.lastDocument, required this.hasMore});
}

