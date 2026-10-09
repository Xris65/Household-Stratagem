import 'dart:async';
import 'auth_service.dart';

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

  /// Closes the underlying stream controller.
  void dispose() {
    _controller.close();
  }
}
