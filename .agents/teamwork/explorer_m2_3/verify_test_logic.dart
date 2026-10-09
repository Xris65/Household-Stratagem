import 'dart:async';
import 'dart:io';

import 'package:household_stratagem/models.dart';

// Standalone in-memory classes matching the proposed service contracts exactly:

abstract class AuthService {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<String> signInAnonymously();
  Future<String> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
}

class FakeAuthService implements AuthService {
  final StreamController<String?> _controller = StreamController<String?>.broadcast();
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

  void simulateAuthChange(String? uid) {
    _currentUserId = uid;
    _controller.add(uid);
  }

  void dispose() {
    _controller.close();
  }
}

abstract class HouseholdRepository {
  Future<UserProfile?> getUserProfile(String userId);
  Future<void> saveUserProfile(UserProfile profile);
  Future<List<Chore>> getChores(String userId);
  Future<void> saveChores(String userId, List<Chore> chores);
  Future<void> updateChore(String userId, Chore chore);
  Future<void> logMission(String userId, MissionLog log);
  Future<List<MissionLog>> getMissionLogs(String userId);
}

class InMemoryHouseholdRepository implements HouseholdRepository {
  final Map<String, UserProfile> _profiles;
  final Map<String, List<Chore>> _chores;
  final Map<String, List<MissionLog>> _logs;
  final List<Chore> seedChores;
  final bool autoSeed;

  InMemoryHouseholdRepository({
    List<Chore>? seedChores,
    this.autoSeed = false,
    Map<String, UserProfile>? initialProfiles,
    Map<String, List<Chore>>? initialChores,
    Map<String, List<MissionLog>>? initialLogs,
  })  : seedChores = seedChores ?? List.unmodifiable(RoomCategory.defaultChores),
        _profiles = initialProfiles != null ? Map.from(initialProfiles) : {},
        _chores = initialChores != null
            ? initialChores.map((k, v) => MapEntry(k, List.from(v)))
            : {},
        _logs = initialLogs != null
            ? initialLogs.map((k, v) => MapEntry(k, List.from(v)))
            : {};

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  @override
  Future<List<Chore>> getChores(String userId) async {
    if (!_chores.containsKey(userId) && autoSeed) {
      seedDefaultsForUser(userId);
    }
    return List<Chore>.from(_chores[userId] ?? []);
  }

  @override
  Future<void> saveChores(String userId, List<Chore> chores) async {
    _chores[userId] = chores.map((c) => c.copyWith()).toList();
  }

  @override
  Future<void> updateChore(String userId, Chore chore) async {
    final list = _chores.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((c) => c.id == chore.id);
    if (idx != -1) {
      list[idx] = chore;
    } else {
      list.add(chore);
    }
  }

  @override
  Future<void> logMission(String userId, MissionLog log) async {
    _logs.putIfAbsent(userId, () => []).add(log);
  }

  @override
  Future<List<MissionLog>> getMissionLogs(String userId) async {
    return List<MissionLog>.from(_logs[userId] ?? []);
  }

  void seedDefaultsForUser(String userId) {
    _chores[userId] = seedChores.map((c) => c.copyWith()).toList();
  }

  void reset() {
    _profiles.clear();
    _chores.clear();
    _logs.clear();
  }
}

abstract class AudioService {
  bool get isPlaying;
  String? get currentTrack;
  Future<void> playMissionLoop(String assetPath);
  Future<void> stop();
  void dispose();
}

class MockAudioService implements AudioService {
  bool _isPlaying = false;
  String? _currentTrack;
  bool _disposed = false;
  int playCount = 0;
  int stopCount = 0;
  final List<String> playedTracks = [];

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentTrack => _currentTrack;

  bool get isDisposed => _disposed;

  @override
  Future<void> playMissionLoop(String assetPath) async {
    if (_disposed) throw StateError('AudioService is disposed');
    if (assetPath.trim().isEmpty) throw ArgumentError('Asset path cannot be empty');
    _isPlaying = true;
    _currentTrack = assetPath;
    playCount++;
    playedTracks.add(assetPath);
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _currentTrack = null;
    stopCount++;
  }

  @override
  void dispose() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = true;
  }

  void reset() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = false;
    playCount = 0;
    stopCount = 0;
    playedTracks.clear();
  }
}

class RealAudioServicePathNormalizer {
  static String normalizeAssetPath(String path) {
    var p = path.trim();
    if (p.isEmpty) throw ArgumentError('Asset path cannot be empty');
    if (p.startsWith('/')) p = p.substring(1);
    if (p.startsWith('assets/')) p = p.substring('assets/'.length);
    if (!p.contains('/') && !p.startsWith('audio/')) p = 'audio/$p';
    return p;
  }
}

int testsRun = 0;
int testsPassed = 0;
int testsFailed = 0;

void expect(dynamic actual, dynamic expected, {String? reason}) {
  if (actual is List && expected is List) {
    if (actual.length != expected.length) {
      throw Exception('Assertion failed: expected length <${expected.length}>, got <${actual.length}>. ${reason ?? ""}');
    }
    for (int i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        throw Exception('Assertion failed: element $i: expected <${expected[i]}>, got <${actual[i]}>. ${reason ?? ""}');
      }
    }
    return;
  }
  if (actual != expected) {
    throw Exception('Assertion failed: expected <$expected>, got <$actual>. ${reason ?? ""}');
  }
}

void expectTrue(bool actual, {String? reason}) {
  if (!actual) throw Exception('Assertion failed: expected true, got false. ${reason ?? ""}');
}

void expectFalse(bool actual, {String? reason}) {
  if (actual) throw Exception('Assertion failed: expected false, got true. ${reason ?? ""}');
}

void expectThrows<T extends Object>(void Function() fn, {String? reason}) {
  try {
    fn();
    throw Exception('Expected exception of type $T, but none thrown.');
  } catch (e) {
    if (e is! T) rethrow;
  }
}

Future<void> expectAsyncThrows<T extends Object>(Future<void> Function() fn, {String? reason}) async {
  try {
    await fn();
    throw Exception('Expected async exception of type $T, but none thrown.');
  } catch (e) {
    if (e is! T) rethrow;
  }
}

Future<void> runTest(String name, Future<void> Function() body) async {
  testsRun++;
  try {
    await body();
    testsPassed++;
    print('  [PASS] $name');
  } catch (e, st) {
    testsFailed++;
    print('  [FAIL] $name: $e');
    print(st);
  }
}

Future<void> main() async {
  print('=== Running Verification Suite for M2 Services Test Design ===');

  print('\n--- Group 1: FakeAuthService Lifecycle & Auth ---');
  await runTest('initial state has null currentUserId', () async {
    final auth = FakeAuthService();
    expect(auth.currentUserId, null);
    auth.dispose();
  });

  await runTest('signInAnonymously sets currentUserId and emits to stream', () async {
    final auth = FakeAuthService();
    final events = <String?>[];
    final sub = auth.authStateChanges.listen((e) => events.add(e));

    final uid = await auth.signInAnonymously();
    expectTrue(uid.startsWith('anon_'));
    expect(auth.currentUserId, uid);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.length, 1);
    expect(events.first, uid);

    await sub.cancel();
    auth.dispose();
  });

  await runTest('signInWithEmailPassword sanitizes email and emits to stream', () async {
    final auth = FakeAuthService();
    final events = <String?>[];
    final sub = auth.authStateChanges.listen((e) => events.add(e));

    final uid = await auth.signInWithEmailPassword('soldier@cleaning.org', 'Pass123!');
    expect(uid, 'user_soldier_cleaning_org');
    expect(auth.currentUserId, 'user_soldier_cleaning_org');

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.length, 1);
    expect(events.first, 'user_soldier_cleaning_org');

    await sub.cancel();
    auth.dispose();
  });

  await runTest('signInWithEmailPassword throws on invalid input', () async {
    final auth = FakeAuthService();
    await expectAsyncThrows<ArgumentError>(() => auth.signInWithEmailPassword('', 'pass'));
    await expectAsyncThrows<ArgumentError>(() => auth.signInWithEmailPassword('   ', 'pass'));
    await expectAsyncThrows<ArgumentError>(() => auth.signInWithEmailPassword('valid@domain.com', ''));
    await expectAsyncThrows<ArgumentError>(() => auth.signInWithEmailPassword('valid@domain.com', '   '));
    auth.dispose();
  });

  await runTest('signOut clears currentUserId and emits null', () async {
    final auth = FakeAuthService();
    final events = <String?>[];
    final sub = auth.authStateChanges.listen((e) => events.add(e));

    await auth.signInAnonymously();
    await auth.signOut();
    expect(auth.currentUserId, null);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.length, 2);
    expect(events.last, null);

    await sub.cancel();
    auth.dispose();
  });

  await runTest('simulateAuthChange updates state and stream', () async {
    final auth = FakeAuthService();
    final events = <String?>[];
    final sub = auth.authStateChanges.listen((e) => events.add(e));

    auth.simulateAuthChange('mock_user_123');
    expect(auth.currentUserId, 'mock_user_123');

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.length, 1);
    expect(events.first, 'mock_user_123');

    await sub.cancel();
    auth.dispose();
  });

  print('\n--- Group 2: InMemoryHouseholdRepository ---');
  await runTest('profile CRUD operations', () async {
    final repo = InMemoryHouseholdRepository(autoSeed: false);
    expect(await repo.getUserProfile('unknown'), null);

    final p1 = UserProfile(
      userId: 'u1',
      agentName: 'Aspirateur-Elite',
      level: 3,
      credits: 500,
      medals: 10,
      onboarded: true,
      selectedAudioTrack: 'tactical_ambiance_2.mp3',
    );
    await repo.saveUserProfile(p1);

    final retrieved = await repo.getUserProfile('u1');
    expect(retrieved?.userId, 'u1');
    expect(retrieved?.agentName, 'Aspirateur-Elite');
    expect(retrieved?.level, 3);
    expect(retrieved?.credits, 500);
    expect(retrieved?.medals, 10);
    expect(retrieved?.onboarded, true);
    expect(retrieved?.selectedAudioTrack, 'tactical_ambiance_2.mp3');
  });

  await runTest('chores saving and updating', () async {
    final repo = InMemoryHouseholdRepository(autoSeed: false);
    expect(await repo.getChores('u1'), <Chore>[]);

    final chores = [
      Chore(id: 'c1', name: 'Plan de travail', room: 'Cuisine', difficulty: 2, periodicityDays: 1),
      Chore(id: 'c2', name: 'Aspirateur', room: 'Salon', difficulty: 3, periodicityDays: 3),
    ];
    await repo.saveChores('u1', chores);
    final fetched = await repo.getChores('u1');
    expect(fetched.length, 2);
    expect(fetched[0].id, 'c1');
    expect(fetched[1].id, 'c2');

    // Update chore
    final updatedC1 = Chore(id: 'c1', name: 'Plan de travail (clean)', room: 'Cuisine', difficulty: 2, periodicityDays: 2);
    await repo.updateChore('u1', updatedC1);
    final afterUpdate = await repo.getChores('u1');
    expect(afterUpdate.length, 2);
    expect(afterUpdate[0].name, 'Plan de travail (clean)');
    expect(afterUpdate[0].periodicityDays, 2);

    // Upsert chore
    final newChore = Chore(id: 'c3', name: 'Vitres', room: 'Salon', difficulty: 4, periodicityDays: 14);
    await repo.updateChore('u1', newChore);
    final afterUpsert = await repo.getChores('u1');
    expect(afterUpsert.length, 3);
  });

  await runTest('autoSeed and seedDefaultsForUser', () async {
    final repoAuto = InMemoryHouseholdRepository(autoSeed: true);
    final choresAuto = await repoAuto.getChores('u_auto');
    expect(choresAuto.length, 17);

    final repoManual = InMemoryHouseholdRepository(autoSeed: false);
    repoManual.seedDefaultsForUser('u_man');
    final choresManual = await repoManual.getChores('u_man');
    expect(choresManual.length, 17);
  });

  await runTest('mission logging and history ordering', () async {
    final repo = InMemoryHouseholdRepository(autoSeed: false);
    expect(await repo.getMissionLogs('u1'), <MissionLog>[]);

    final log1 = MissionLog(
      id: 'l1',
      choreId: 'c1',
      choreName: 'Plan de travail',
      room: 'Cuisine',
      completedAt: DateTime(2026, 10, 4, 10, 0),
      durationSeconds: 300,
      success: true,
    );
    final log2 = MissionLog(
      id: 'l2',
      choreId: 'c2',
      choreName: 'Aspirateur',
      room: 'Salon',
      completedAt: DateTime(2026, 10, 4, 11, 0),
      durationSeconds: 500,
      success: true,
    );

    await repo.logMission('u1', log1);
    await repo.logMission('u1', log2);

    final logs = await repo.getMissionLogs('u1');
    expect(logs.length, 2);
    expect(logs[0].id, 'l1');
    expect(logs[1].id, 'l2');
  });

  await runTest('multi-user isolation and reset', () async {
    final repo = InMemoryHouseholdRepository(autoSeed: false);
    await repo.saveUserProfile(UserProfile(userId: 'ua', agentName: 'Alpha'));
    await repo.saveUserProfile(UserProfile(userId: 'ub', agentName: 'Beta'));
    await repo.saveChores('ua', [Chore(id: 'ca', name: 'Task A', difficulty: 1)]);
    await repo.saveChores('ub', [Chore(id: 'cb', name: 'Task B', difficulty: 2)]);

    expect((await repo.getUserProfile('ua'))?.agentName, 'Alpha');
    expect((await repo.getUserProfile('ub'))?.agentName, 'Beta');
    expect((await repo.getChores('ua')).length, 1);
    expect((await repo.getChores('ub')).length, 1);

    repo.reset();
    expect(await repo.getUserProfile('ua'), null);
    expect(await repo.getChores('ua'), <Chore>[]);
  });

  print('\n--- Group 3: MockAudioService Lifecycle ---');
  await runTest('mock audio playback, stop, track switching, reset', () async {
    final audio = MockAudioService();
    expect(audio.isPlaying, false);
    expect(audio.currentTrack, null);
    expect(audio.isDisposed, false);

    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    expect(audio.isPlaying, true);
    expect(audio.currentTrack, 'tactical_ambiance_1.mp3');
    expect(audio.playCount, 1);

    // Track switch
    await audio.playMissionLoop('tactical_ambiance_2.mp3');
    expect(audio.isPlaying, true);
    expect(audio.currentTrack, 'tactical_ambiance_2.mp3');
    expect(audio.playCount, 2);

    // Stop
    await audio.stop();
    expect(audio.isPlaying, false);
    expect(audio.currentTrack, null);
    expect(audio.stopCount, 1);

    // Reset
    audio.reset();
    expect(audio.playCount, 0);
    expect(audio.stopCount, 0);

    // Validation
    await expectAsyncThrows<ArgumentError>(() => audio.playMissionLoop(''));
    await expectAsyncThrows<ArgumentError>(() => audio.playMissionLoop('   '));

    // Dispose
    audio.dispose();
    expect(audio.isDisposed, true);
    await expectAsyncThrows<StateError>(() => audio.playMissionLoop('track.mp3'));
  });

  print('\n--- Group 4: RealAudioService Path Normalization ---');
  await runTest('path normalization rules', () async {
    expect(RealAudioServicePathNormalizer.normalizeAssetPath('assets/audio/tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(RealAudioServicePathNormalizer.normalizeAssetPath('audio/tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(RealAudioServicePathNormalizer.normalizeAssetPath('tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(RealAudioServicePathNormalizer.normalizeAssetPath('/assets/audio/tactical_ambiance_2.mp3'), 'audio/tactical_ambiance_2.mp3');
    expect(RealAudioServicePathNormalizer.normalizeAssetPath('   tactical_ambiance_2.mp3   '), 'audio/tactical_ambiance_2.mp3');

    expectThrows<ArgumentError>(() => RealAudioServicePathNormalizer.normalizeAssetPath(''));
    expectThrows<ArgumentError>(() => RealAudioServicePathNormalizer.normalizeAssetPath('   '));
  });

  print('\n=== Verification Summary ===');
  print('Total tests run: $testsRun');
  print('Passed: $testsPassed');
  print('Failed: $testsFailed');

  if (testsFailed > 0) {
    exit(1);
  }
}
