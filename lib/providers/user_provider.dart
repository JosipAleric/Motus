import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Stream FirebaseAuth User
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// FutureProvider for complete UserModel from Firestore
final currentUserFutureProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return null;

  final userService = ref.read(firestoreServiceProvider);
  return await userService.getUserById(authUser.uid);
});

// StreamProvider for real-time UserModel updates from Firestore
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) return const Stream.empty();

  final userService = ref.read(firestoreServiceProvider);
  return userService.userDocumentStream(authUser.uid);
});

