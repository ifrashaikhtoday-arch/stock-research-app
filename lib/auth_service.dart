import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Stream — listens to login/logout changes in real time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SIGN UP with email & password
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOG IN with email & password
  Future<String?> logIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOG OUT
  Future<void> logOut() async {
    await _auth.signOut();
  }
}