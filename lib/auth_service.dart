import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> logIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logOut() async {
    await _auth.signOut();
  }

  Future<bool> hasCompletedOnboarding() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return doc.data()?['onboardingComplete'] == true;
    } catch (e) {
      // If Firestore fails, skip onboarding
      return true;
    }
  }

  // ===========================================================
  // PUSH NOTIFICATIONS (FCM) SETUP
  // ===========================================================
  //
  // This asks the user for notification permission, grabs the
  // unique FCM token for this device, and saves it to their
  // Firestore user document. Our backend's cron job reads this
  // token to know where to send price alert notifications.
  //
  // Call this right after a successful login or signup.
  Future<void> registerFcmToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final messaging = FirebaseMessaging.instance;

      // Ask the user for notification permission (mainly needed on iOS,
      // harmless to call on Android too).
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get this device's unique FCM token.
      final token = await messaging.getToken();

      if (token == null) return;

      // Save it to Firestore under the user's document.
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true), // merge: true means we don't overwrite other fields
      );

      // Optional: keep the token updated if it ever refreshes
      // (FCM tokens can change over time, e.g. after app reinstall).
      messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      // If this fails, the user just won't get push notifications --
      // shouldn't block login/signup from succeeding.
      print('Error registering FCM token: $e');
    }
  }
}