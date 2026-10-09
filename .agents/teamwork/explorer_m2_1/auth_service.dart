import 'dart:async';

/// Contract for authentication operations in HouseholdStratagem.
abstract class AuthService {
  /// Stream emitting the currently signed-in user's UID, or null when signed out.
  Stream<String?> get authStateChanges;

  /// The currently signed-in user's UID, or null if unauthenticated.
  String? get currentUserId;

  /// Signs in anonymously and returns the user's UID.
  Future<String> signInAnonymously();

  /// Signs in using email and password credentials and returns the user's UID.
  Future<String> signInWithEmailPassword(String email, String password);

  /// Signs out the active user session.
  Future<void> signOut();
}
