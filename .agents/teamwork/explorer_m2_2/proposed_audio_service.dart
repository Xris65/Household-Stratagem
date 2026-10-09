import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Contract for household mission audio playback.
///
/// Implemented by [RealAudioService] using `audioplayers` for device execution,
/// and [MockAudioService] for fast headless unit/widget testing.
abstract class AudioService {
  /// Whether an audio track is currently playing.
  bool get isPlaying;

  /// The currently playing audio track identifier or asset path, or `null` if stopped.
  String? get currentTrack;

  /// Starts or switches playback of a local audio asset in an infinite loop.
  ///
  /// Normalizes asset paths such that `"assets/audio/..."`, `"audio/..."`, or
  /// raw filenames like `"tactical_ambiance_1.mp3"` correctly resolve to the
  /// bundled asset location.
  ///
  /// Throws [ArgumentError] if [assetPath] is empty or whitespace.
  /// Throws [StateError] if this service has already been disposed.
  Future<void> playMissionLoop(String assetPath);

  /// Stops active playback. Safe to call multiple times or when already stopped.
  Future<void> stop();

  /// Releases audio resources and stops playback.
  void dispose();
}

/// Production implementation of [AudioService] wrapping [AudioPlayer] from `audioplayers`.
class RealAudioService implements AudioService {
  final AudioPlayer _player;
  bool _isPlaying = false;
  String? _currentTrack;
  bool _disposed = false;
  StreamSubscription<PlayerState>? _stateSubscription;

  /// Creates a [RealAudioService]. An existing or mock [AudioPlayer] can be injected for testing.
  RealAudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        if (!_disposed && state == PlayerState.stopped) {
          _isPlaying = false;
        }
      } else if (state == PlayerState.playing) {
        _isPlaying = true;
      }
    });
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentTrack => _currentTrack;

  /// Whether this service instance has been disposed.
  bool get isDisposed => _disposed;

  /// Normalizes asset path strings for `audioplayers.AssetSource`.
  ///
  /// Because `audioplayers` defaults its asset cache prefix to `'assets/'`,
  /// passing a path starting with `'assets/'` will result in duplicate prefixes.
  /// This method strips any leading `'assets/'` or `'/'`, and ensures raw
  /// track filenames (e.g. `'tactical_ambiance_1.mp3'`) are placed in `'audio/'`.
  static String normalizeAssetPath(String path) {
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

  @override
  Future<void> playMissionLoop(String assetPath) async {
    if (_disposed) {
      throw StateError('AudioService is disposed');
    }
    if (assetPath.trim().isEmpty) {
      throw ArgumentError('Asset path cannot be empty');
    }

    final normalizedPath = normalizeAssetPath(assetPath);
    _currentTrack = assetPath;
    _isPlaying = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(normalizedPath));
    } catch (e) {
      // Allow callers or error boundaries to handle platform exceptions
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _currentTrack = null;
    try {
      await _player.stop();
    } catch (_) {
      // Ignored during graceful stop
    }
  }

  @override
  void dispose() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = true;
    _stateSubscription?.cancel();
    _stateSubscription = null;
    try {
      _player.dispose();
    } catch (_) {
      // Ignored during disposal
    }
  }
}

/// In-memory mock of [AudioService] for headless unit and widget testing.
///
/// Executes without requiring native platform channels or plugin bindings.
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

  /// Whether this mock has been disposed.
  bool get isDisposed => _disposed;

  @override
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

  /// Resets all mock recording counters and state flags.
  void reset() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = false;
    playCount = 0;
    stopCount = 0;
    playedTracks.clear();
  }
}
