import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Future<User?> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      final newUser = UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      await _firestore.saveUser(newUser);
    }
    return user;
  }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<void> logout() async => await _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
