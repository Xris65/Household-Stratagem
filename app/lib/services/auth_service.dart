import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Contract for authentication operations in HouseholdStratagem.
///
/// Supports anonymous and email/password sign-in, session inspection,
/// and reactive auth state listening.
abstract class AuthService {
  /// Stream emitting the currently signed-in user's UID, or null when signed out.
  Stream<String?> get authStateChanges;

  /// The currently signed-in user's UID, or null if unauthenticated.
  String? get currentUserId;

  /// Signs in anonymously and returns the user's UID.
  Future<String> signInAnonymously();

  /// Signs in using email and password credentials and returns the user's UID.
  ///
  /// Throws [ArgumentError] if [email] or [password] are empty or whitespace.
  Future<String> signInWithEmailPassword(String email, String password);

  /// Signs out the active user session.
  Future<void> signOut();
}

/// Production implementation of [AuthService] backed by Firebase Authentication.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  /// If true, attempts to automatically create the account when signInWithEmailAndPassword
  /// encounters a 'user-not-found' or 'invalid-credential' error (useful for seamless demo mode).
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

/// In-memory / Mock implementation of [AuthService] for offline demo mode
/// and headless testing without Firebase dependencies.
class FakeAuthService implements AuthService {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  String? _currentUserId;

  FakeAuthService({String? initialUserId}) : _currentUserId = initialUserId;

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<String> signInAnonymously() async {
    final uid = 'anon_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = uid;
    _controller.add(uid);
    return uid;
  }

  @override
  Future<String> signInWithEmailPassword(String email, String password) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw ArgumentError('Email and password must not be empty');
    }
    final sanitizedEmail = trimmedEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final uid = 'user_$sanitizedEmail';
    _currentUserId = uid;
    _controller.add(uid);
    return uid;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _controller.add(null);
  }

  /// Manually simulates an auth state transition for testing.
  void simulateAuthChange(String? uid) {
    _currentUserId = uid;
    _controller.add(uid);
  }

  /// Closes the stream controller.
  void dispose() {
    _controller.close();
  }
}
