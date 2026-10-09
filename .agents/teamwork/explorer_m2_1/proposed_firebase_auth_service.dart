import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Production implementation of [AuthService] backed by Firebase Authentication.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  /// If true, attempts to automatically create the account when signInWithEmailAndPassword
  /// encounters a 'user-not-found' or 'invalid-credential' error.
  final bool autoRegisterIfNotFound;

  FirebaseAuthService({
    FirebaseAuth? auth,
    this.autoRegisterIfNotFound = false,
  }) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Firebase anonymous sign-in failed to produce a user UID');
    }
    return uid;
  }

  @override
  Future<String> signInWithEmailPassword(String email, String password) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw ArgumentError('Email and password must not be empty');
    }

    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'user-not-found' || e.code == 'invalid-credential') &&
          autoRegisterIfNotFound) {
        credential = await _auth.createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
      } else {
        rethrow;
      }
    }

    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Firebase email/password sign-in failed to produce a user UID');
    }
    return uid;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
