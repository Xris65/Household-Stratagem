import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata definition for a selectable mission soundtrack track.
class MissionAudioTrack {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final String artist;
  final String license;

  const MissionAudioTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.artist,
    required this.license,
  });
}

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

  /// Whether background music is currently enabled.
  bool get musicEnabled;

  /// ValueNotifier that fires when musicEnabled changes.
  ValueNotifier<bool> get musicEnabledNotifier;

  /// Toggles the background music state.
  void toggleMusic();

  /// Sets whether background music is enabled.
  Future<void> setMusicEnabled(bool enabled);

  /// Whether the audio is currently muted.
  bool get isMuted;

  /// ValueNotifier that fires when isMuted changes.
  ValueNotifier<bool> get muteNotifier;

  /// Toggles the mute state.
  void toggleMute();

  /// Whether SFX are enabled.
  bool get sfxEnabled;

  /// ValueNotifier that fires when SFX enabled state changes.
  ValueNotifier<bool> get sfxEnabledNotifier;

  /// Toggles the SFX state.
  void toggleSfx();

  /// Sets whether SFX are enabled.
  Future<void> setSfxEnabled(bool enabled);

  /// Currently selected mission audio track filename.
  String get selectedTrack;

  /// ValueNotifier that fires when the selected mission track changes.
  ValueNotifier<String> get selectedTrackNotifier;

  /// Sets the selected mission audio track and persists the preference.
  Future<void> setSelectedTrack(String track);

  /// Plays the swipe SFX with ultra-low latency and non-clipping concurrency.
  Future<void> playSwipe();

  /// Plays the deploy SFX.
  Future<void> playDeploy();

  /// Plays the victory SFX.
  Future<void> playVictory();

  /// Releases audio resources and stops playback.
  void dispose();
}

/// Production implementation of [AudioService] wrapping [AudioPlayer] from `audioplayers`.
class RealAudioService implements AudioService {
  final AudioPlayer _player;
  static const int _swipePoolSize = 4;
  final List<AudioPlayer> _swipePool = [];
  int _swipePoolIndex = 0;
  final AudioPlayer _deployPlayer;
  final AudioPlayer _victoryPlayer;

  bool _isPlaying = false;
  String? _currentTrack;
  bool _disposed = false;

  static const List<MissionAudioTrack> missionTracks = [
    MissionAudioTrack(
      id: 'tactical_ambiance_1.mp3',
      title: 'Mission Alpha: Epic Battle',
      subtitle: 'Rythme martial & percussions tactiques',
      assetPath: 'tactical_ambiance_1.mp3',
      artist: 'Cj Aist',
      license: 'CC BY 3.0',
    ),
    MissionAudioTrack(
      id: 'tactical_ambiance_2.mp3',
      title: 'Mission Bravo: Tactical Questionmark',
      subtitle: 'Tension opérationnelle & marche héroïque',
      assetPath: 'tactical_ambiance_2.mp3',
      artist: 'Antti Luode',
      license: 'CC BY 3.0',
    ),
    MissionAudioTrack(
      id: 'tactical_ambiance_3.mp3',
      title: 'Mission Charlie: Heavy Recon',
      subtitle: 'Infiltration lourde & suspense tactique',
      assetPath: 'tactical_ambiance_3.mp3',
      artist: 'Antti Luode',
      license: 'CC BY 3.0',
    ),
  ];

  static RealAudioService _instance = RealAudioService._internal();

  /// Creates a [RealAudioService]. Returns a singleton instance.
  factory RealAudioService({AudioPlayer? player}) {
    if (player != null) return RealAudioService._internal(player: player);
    if (_instance._disposed) {
      _instance = RealAudioService._internal();
    }
    return _instance;
  }

  RealAudioService._internal({AudioPlayer? player})
      : _player = player ?? AudioPlayer(),
        _deployPlayer = AudioPlayer()
          ..setPlayerMode(PlayerMode.lowLatency)
          ..setReleaseMode(ReleaseMode.stop)
          ..setVolume(0.9),
        _victoryPlayer = AudioPlayer()
          ..setPlayerMode(PlayerMode.lowLatency)
          ..setReleaseMode(ReleaseMode.stop)
          ..setVolume(0.9) {
    for (int i = 0; i < _swipePoolSize; i++) {
      final p = AudioPlayer();
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setReleaseMode(ReleaseMode.stop);
      p.setVolume(0.85);
      _swipePool.add(p);
    }
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('musicEnabled')) {
        await prefs.setBool('musicEnabled', true);
      }
      final music = prefs.getBool('musicEnabled') ??
          !(prefs.getBool('musicMuted') ?? false);
      _musicEnabledNotifier.value = music;
      _muteNotifier.value = !music;

      if (!prefs.containsKey('sfxEnabled')) {
        await prefs.setBool('sfxEnabled', true);
      }
      _sfxNotifier.value = prefs.getBool('sfxEnabled') ?? true;

      final track = prefs.getString('selectedAudioTrack') ??
          'tactical_ambiance_1.mp3';
      _selectedTrackNotifier.value = track;

      if (_isPlaying) {
        _player.setVolume(music ? 1.0 : 0.0);
      }
    } catch (_) {}

    // Pre-cache sound files into AudioCache to guarantee instantaneous playback
    try {
      await AudioCache.instance.loadPath('audio/swipe.wav');
      await AudioCache.instance.loadPath('audio/deploy.wav');
      await AudioCache.instance.loadPath('audio/victory.wav');
      await AudioCache.instance.loadPath('audio/tactical_ambiance_1.mp3');
      await AudioCache.instance.loadPath('audio/tactical_ambiance_2.mp3');
      await AudioCache.instance.loadPath('audio/tactical_ambiance_3.mp3');
    } catch (_) {}
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentTrack => _currentTrack;

  /// Whether this service instance has been disposed.
  bool get isDisposed => _disposed;

  /// Normalizes asset path strings for `audioplayers.AssetSource`.
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
    if (_disposed) return;
    final p = RealAudioService.normalizeAssetPath(assetPath);
    if (_isPlaying && _currentTrack == p) return;

    _currentTrack = p;
    _isPlaying = true;
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(musicEnabled ? 1.0 : 0.0);
    try {
      await _player.play(AssetSource(p));
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _currentTrack = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  bool get musicEnabled => _musicEnabledNotifier.value;

  final ValueNotifier<bool> _musicEnabledNotifier = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool> get musicEnabledNotifier => _musicEnabledNotifier;

  @override
  void toggleMusic() => toggleMute();

  @override
  bool get isMuted => _muteNotifier.value;

  final ValueNotifier<bool> _muteNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get muteNotifier => _muteNotifier;

  @override
  void toggleMute() async {
    final newMuted = !_muteNotifier.value;
    _muteNotifier.value = newMuted;
    _musicEnabledNotifier.value = !newMuted;
    if (_isPlaying) {
      _player.setVolume(newMuted ? 0.0 : 1.0);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('musicMuted', newMuted);
      await prefs.setBool('musicEnabled', !newMuted);
    } catch (_) {}
  }

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabledNotifier.value == enabled) return;
    _musicEnabledNotifier.value = enabled;
    _muteNotifier.value = !enabled;
    if (_isPlaying) {
      _player.setVolume(enabled ? 1.0 : 0.0);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('musicEnabled', enabled);
      await prefs.setBool('musicMuted', !enabled);
    } catch (_) {}
  }

  @override
  bool get sfxEnabled => _sfxNotifier.value;

  final ValueNotifier<bool> _sfxNotifier = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool> get sfxEnabledNotifier => _sfxNotifier;

  @override
  void toggleSfx() async {
    final next = !_sfxNotifier.value;
    _sfxNotifier.value = next;
    if (!next) {
      _stopAllSfx();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sfxEnabled', next);
    } catch (_) {}
  }

  @override
  Future<void> setSfxEnabled(bool enabled) async {
    if (_sfxNotifier.value == enabled) return;
    _sfxNotifier.value = enabled;
    if (!enabled) {
      _stopAllSfx();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sfxEnabled', enabled);
    } catch (_) {}
  }

  void _stopAllSfx() {
    for (final p in _swipePool) {
      try {
        p.stop();
      } catch (_) {}
    }
    try {
      _deployPlayer.stop();
    } catch (_) {}
    try {
      _victoryPlayer.stop();
    } catch (_) {}
  }

  @override
  String get selectedTrack => _selectedTrackNotifier.value;

  final ValueNotifier<String> _selectedTrackNotifier =
      ValueNotifier<String>('tactical_ambiance_1.mp3');

  @override
  ValueNotifier<String> get selectedTrackNotifier => _selectedTrackNotifier;

  @override
  Future<void> setSelectedTrack(String track) async {
    _selectedTrackNotifier.value = track;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedAudioTrack', track);
    } catch (_) {}
    if (_isPlaying) {
      await playMissionLoop(track);
    }
  }

  @override
  Future<void> playSwipe() async {
    if (!sfxEnabled || _disposed) return;
    try {
      if (_swipePool.isNotEmpty) {
        final player = _swipePool[_swipePoolIndex];
        _swipePoolIndex = (_swipePoolIndex + 1) % _swipePool.length;
        await player.stop();
        await player.play(AssetSource('audio/swipe.wav'));
      }
    } catch (_) {}
  }

  @override
  Future<void> playDeploy() async {
    if (!sfxEnabled || _disposed) return;
    try {
      await _deployPlayer.stop();
      await _deployPlayer.play(AssetSource('audio/deploy.wav'));
    } catch (_) {}
  }

  @override
  Future<void> playVictory() async {
    if (!sfxEnabled || _disposed) return;
    try {
      await _victoryPlayer.stop();
      await _victoryPlayer.play(AssetSource('audio/victory.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = true;
    try {
      _player.stop();
      _stopAllSfx();
    } catch (_) {}
  }
}

/// In-memory mock of [AudioService] for headless unit and widget testing.
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
    if (_disposed) throw StateError('AudioService is already disposed');
    final trimmed = assetPath.trim();
    if (trimmed.isEmpty) {
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
  bool get musicEnabled => _musicEnabledNotifier.value;

  final ValueNotifier<bool> _musicEnabledNotifier = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool> get musicEnabledNotifier => _musicEnabledNotifier;

  @override
  void toggleMusic() => toggleMute();

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabledNotifier.value != enabled) {
      toggleMusic();
    }
  }

  @override
  bool get isMuted => _muteNotifier.value;

  final ValueNotifier<bool> _muteNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get muteNotifier => _muteNotifier;

  @override
  void toggleMute() {
    _muteNotifier.value = !_muteNotifier.value;
    _musicEnabledNotifier.value = !_muteNotifier.value;
  }

  @override
  bool get sfxEnabled => _sfxNotifier.value;

  final ValueNotifier<bool> _sfxNotifier = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool> get sfxEnabledNotifier => _sfxNotifier;

  @override
  void toggleSfx() {
    _sfxNotifier.value = !_sfxNotifier.value;
  }

  @override
  Future<void> setSfxEnabled(bool enabled) async {
    _sfxNotifier.value = enabled;
  }

  @override
  String get selectedTrack => _selectedTrackNotifier.value;

  final ValueNotifier<String> _selectedTrackNotifier =
      ValueNotifier<String>('tactical_ambiance_1.mp3');

  @override
  ValueNotifier<String> get selectedTrackNotifier => _selectedTrackNotifier;

  @override
  Future<void> setSelectedTrack(String track) async {
    _selectedTrackNotifier.value = track;
    if (_isPlaying) {
      await playMissionLoop(track);
    }
  }

  @override
  Future<void> playSwipe() async {}

  @override
  Future<void> playDeploy() async {}

  @override
  Future<void> playVictory() async {}

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
    _sfxNotifier.value = true;
    _muteNotifier.value = false;
    _musicEnabledNotifier.value = true;
    _selectedTrackNotifier.value = 'tactical_ambiance_1.mp3';
  }
}
