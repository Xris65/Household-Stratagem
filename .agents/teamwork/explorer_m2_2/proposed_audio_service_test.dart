// Comprehensive unit tests for AudioService contracts, MockAudioService, and path normalization.
//
// These tests can be merged into `app/test/unit/services_test.dart` or
// `app/test/unit/audio_service_test.dart` during Milestone M2 implementation.

import 'dart:async';

void expect(dynamic actual, dynamic expected, {String? reason}) {
  if (actual != expected) {
    throw Exception('Assertion failed: expected <$expected>, got <$actual>. ${reason ?? ""}');
  }
}

void expectTrue(bool actual, {String? reason}) {
  if (!actual) {
    throw Exception('Assertion failed: expected true, got false. ${reason ?? ""}');
  }
}

void expectFalse(bool actual, {String? reason}) {
  if (actual) {
    throw Exception('Assertion failed: expected false, got true. ${reason ?? ""}');
  }
}

void expectThrows<T extends Object>(void Function() fn, {String? reason}) {
  try {
    fn();
    throw Exception('Assertion failed: expected exception of type $T, but no exception was thrown. ${reason ?? ""}');
  } catch (e) {
    if (e is! T) {
      throw Exception('Assertion failed: expected exception of type $T, but got ${e.runtimeType}: $e. ${reason ?? ""}');
    }
  }
}

Future<void> expectAsyncThrows<T extends Object>(Future<void> Function() fn, {String? reason}) async {
  try {
    await fn();
    throw Exception('Assertion failed: expected async exception of type $T, but no exception was thrown. ${reason ?? ""}');
  } catch (e) {
    if (e is! T) {
      throw Exception('Assertion failed: expected async exception of type $T, but got ${e.runtimeType}: $e. ${reason ?? ""}');
    }
  }
}

/// Standalone test implementation of MockAudioService mirroring proposed_audio_service.dart
class StandaloneMockAudioService {
  bool _isPlaying = false;
  String? _currentTrack;
  bool _disposed = false;
  int playCount = 0;
  int stopCount = 0;
  final List<String> playedTracks = [];

  bool get isPlaying => _isPlaying;
  String? get currentTrack => _currentTrack;
  bool get isDisposed => _disposed;

  Future<void> playMissionLoop(String assetPath) async {
    if (_disposed) {
      throw StateError('AudioService is disposed');
    }
    if (assetPath.trim().isEmpty) {
      throw ArgumentError('Asset path cannot be empty');
    }
    _isPlaying = true;
    _currentTrack = assetPath;
    playCount++;
    playedTracks.add(assetPath);
  }

  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _currentTrack = null;
    stopCount++;
  }

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

/// Normalization logic from RealAudioService
String normalizeAssetPath(String path) {
  var p = path.trim();
  if (p.isEmpty) {
    throw ArgumentError('Asset path cannot be empty');
  }
  if (p.startsWith('/')) {
    p = p.substring(1);
  }
  if (p.startsWith('assets/')) {
    p = p.substring('assets/'.length);
  }
  if (!p.contains('/') && !p.startsWith('audio/')) {
    p = 'audio/$p';
  }
  return p;
}

Future<void> main() async {
  print('=== Running AudioService Proposed Test Suite ===');

  // Test 1: Initial State
  {
    final audio = StandaloneMockAudioService();
    expectFalse(audio.isPlaying, reason: 'Initially should not be playing');
    expect(audio.currentTrack, null, reason: 'Initially currentTrack should be null');
    expectFalse(audio.isDisposed, reason: 'Initially should not be disposed');
    expect(audio.playCount, 0);
    expect(audio.stopCount, 0);
    print('  [PASS] Test 1: Initial state verification');
  }

  // Test 2: Play Loop and Track Switching
  {
    final audio = StandaloneMockAudioService();
    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    expectTrue(audio.isPlaying);
    expect(audio.currentTrack, 'tactical_ambiance_1.mp3');
    expect(audio.playCount, 1);
    expect(audio.playedTracks.length, 1);

    // Switch track while playing
    await audio.playMissionLoop('tactical_ambiance_2.mp3');
    expectTrue(audio.isPlaying);
    expect(audio.currentTrack, 'tactical_ambiance_2.mp3');
    expect(audio.playCount, 2);
    expect(audio.playedTracks.length, 2);
    expect(audio.playedTracks[0], 'tactical_ambiance_1.mp3');
    expect(audio.playedTracks[1], 'tactical_ambiance_2.mp3');
    print('  [PASS] Test 2: Play loop and track switching');
  }

  // Test 3: Stop Playback
  {
    final audio = StandaloneMockAudioService();
    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    expectTrue(audio.isPlaying);

    await audio.stop();
    expectFalse(audio.isPlaying);
    expect(audio.currentTrack, null);
    expect(audio.stopCount, 1);

    // Idempotent stop
    await audio.stop();
    expectFalse(audio.isPlaying);
    expect(audio.stopCount, 2);
    print('  [PASS] Test 3: Stop playback and idempotent stop');
  }

  // Test 4: Disposal Lifecycle
  {
    final audio = StandaloneMockAudioService();
    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    audio.dispose();
    expectFalse(audio.isPlaying);
    expect(audio.currentTrack, null);
    expectTrue(audio.isDisposed);

    // Disposed play throws StateError
    await expectAsyncThrows<StateError>(() => audio.playMissionLoop('tactical_ambiance_1.mp3'));

    // Disposed stop is a safe no-op
    await audio.stop();
    expect(audio.stopCount, 0, reason: 'Stop when disposed should not increment stop count');
    print('  [PASS] Test 4: Disposal lifecycle and guards');
  }

  // Test 5: Input Validation on Empty Asset Path
  {
    final audio = StandaloneMockAudioService();
    await expectAsyncThrows<ArgumentError>(() => audio.playMissionLoop(''));
    await expectAsyncThrows<ArgumentError>(() => audio.playMissionLoop('   '));
    expectFalse(audio.isPlaying);
    expect(audio.playCount, 0);
    print('  [PASS] Test 5: Rejection of empty/whitespace paths');
  }

  // Test 6: Mock Reset
  {
    final audio = StandaloneMockAudioService();
    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    await audio.stop();
    audio.dispose();
    audio.reset();

    expectFalse(audio.isPlaying);
    expect(audio.currentTrack, null);
    expectFalse(audio.isDisposed);
    expect(audio.playCount, 0);
    expect(audio.stopCount, 0);
    expect(audio.playedTracks.isEmpty, true);

    // After reset, playing works again
    await audio.playMissionLoop('tactical_ambiance_1.mp3');
    expectTrue(audio.isPlaying);
    print('  [PASS] Test 6: Mock reset method resets all state');
  }

  // Test 7: Asset Path Normalization Logic
  {
    expect(normalizeAssetPath('tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(normalizeAssetPath('audio/tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(normalizeAssetPath('assets/audio/tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(normalizeAssetPath('/assets/audio/tactical_ambiance_1.mp3'), 'audio/tactical_ambiance_1.mp3');
    expect(normalizeAssetPath('   assets/audio/tactical_ambiance_2.mp3   '), 'audio/tactical_ambiance_2.mp3');
    expect(normalizeAssetPath('custom_folder/sound.mp3'), 'custom_folder/sound.mp3');
    expectThrows<ArgumentError>(() => normalizeAssetPath(''));
    expectThrows<ArgumentError>(() => normalizeAssetPath('   '));
    print('  [PASS] Test 7: Asset path normalization variations');
  }

  print('=== ALL 7 AUDIO TESTS PASSED SUCCESSFULLY ===');
}
