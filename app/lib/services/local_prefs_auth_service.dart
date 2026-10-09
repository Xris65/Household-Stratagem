import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:household_stratagem/services/auth_service.dart';

class LocalPrefsAuthService implements AuthService {
  final StreamController<String?> _controller = StreamController<String?>.broadcast();
  String? _currentUserId;

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentUserId => _currentUserId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('offline_fake_uid');
    if (uid != null) {
      _currentUserId = uid;
      _controller.add(uid);
    }
  }

  @override
  Future<String> signInAnonymously() async {
    final uid = 'anon_${DateTime.now().millisecondsSinceEpoch}';
    await _persistUid(uid);
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
    await _persistUid(uid);
    return uid;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _controller.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_fake_uid');
  }

  Future<void> _persistUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_fake_uid', uid);
    _currentUserId = uid;
    _controller.add(uid);
  }

  void dispose() {
    _controller.close();
  }
}
