import 'dart:async';
import 'package:flutter/widgets.dart';
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

/// Contract for household mission audio playback, SFX, and ambient soundtrack loops.
///
/// Implemented by [RealAudioService] using `audioplayers` for device execution,
/// and [MockAudioService] for fast headless unit/widget testing.
abstract class AudioService {
  /// Filename of the global bridge ambient soundtrack.
  static const String bridgeAmbianceTrack = 'bridge_ambiance.mp3';

  /// Preloads and warms up all SFX buffers (round-robin swipe pool, deploy, victory)
  /// and soundtrack buffers into memory to guarantee zero-latency playback on first interaction.
  Future<void> warmUp();

  /// Whether a mission audio track is currently playing.
  bool get isPlaying;

  /// Alias for [isPlaying] indicating if mission soundtrack loop is active.
  bool get isMissionPlaying;

  /// Whether mission playback is currently paused.
  bool get isMissionPaused;

  /// The currently playing audio track identifier or asset path, or `null` if stopped.
  String? get currentTrack;

  /// Starts or switches playback of a local audio asset in an infinite loop.
  ///
  /// Normalizes asset paths such that `"assets/audio/..."`, `"audio/..."`, or
  /// raw filenames like `"tactical_ambiance_1.mp3"` correctly resolve to the
  /// bundled asset location.
  ///
  /// Automatically pauses global bridge ambiance if it was playing.
  ///
  /// Throws [ArgumentError] if [assetPath] is empty or whitespace.
  /// Throws [StateError] if this service has already been disposed.
  Future<void> playMissionLoop(String assetPath);

  /// Pauses the active mission loop without losing player position or state.
  Future<void> pauseMissionLoop();

  /// Resumes the paused active mission loop.
  Future<void> resumeMissionLoop();

  /// Stops active mission playback and smoothly resumes global bridge ambiance if it was active.
  /// Safe to call multiple times or when already stopped.
  Future<void> stop();

  /// Whether the global bridge ambient track is currently playing.
  bool get isBridgePlaying;

  /// ValueNotifier that fires when bridge ambiance playing state changes.
  ValueNotifier<bool> get bridgePlayingNotifier;

  /// Starts playing the global bridge ambient soundtrack in a continuous loop.
  ///
  /// If a mission track is already active, this will defer until the mission finishes.
  Future<void> playBridgeLoop();

  /// Stops the bridge ambient loop.
  Future<void> stopBridgeLoop();

  /// Smoothly resumes the bridge ambient loop (e.g. after exiting a mission).
  Future<void> resumeBridgeLoop();

  /// Pauses the general app ambiance (bridge loop) without losing state.
  Future<void> pauseBridgeLoop();

  /// Pauses general app ambiance (alias for [pauseBridgeLoop]).
  Future<void> pauseAppAmbiance();

  /// Resumes general app ambiance (bridge loop) if enabled and not currently playing a mission.
  Future<void> resumeAppAmbiance();

  /// Handles [AppLifecycleState] changes:
  /// - When state != [AppLifecycleState.resumed]: immediately pauses general app ambiance.
  /// - When state == [AppLifecycleState.resumed]: resumes general app ambiance if [isOnMenu] is true
  ///   and [appAmbianceEnabled] is true.
  /// Mission music continues playing regardless of lifecycle transitions.
  Future<void> handleAppLifecycleState(AppLifecycleState state, {bool isOnMenu = true});

  /// Whether general app ambiance (Home/Settings) is enabled.
  bool get appAmbianceEnabled;

  /// ValueNotifier that fires when appAmbianceEnabled changes.
  ValueNotifier<bool> get appAmbianceNotifier;

  /// Toggles general app ambiance state and persists to storage.
  void toggleAppAmbiance();

  /// Sets whether general app ambiance is enabled and persists to storage.
  Future<void> setAppAmbianceEnabled(bool enabled);

  /// Whether tactical mission music (TimerScreen) is enabled.
  bool get missionMusicEnabled;

  /// ValueNotifier that fires when missionMusicEnabled changes.
  ValueNotifier<bool> get missionMusicNotifier;

  /// Toggles tactical mission music state and persists to storage.
  void toggleMissionMusic();

  /// Sets whether tactical mission music is enabled and persists to storage.
  Future<void> setMissionMusicEnabled(bool enabled);

  /// Legacy alias for [missionMusicEnabled] for backwards compatibility.
  bool get musicEnabled;

  /// Legacy alias for [missionMusicNotifier] for backwards compatibility.
  ValueNotifier<bool> get musicEnabledNotifier;

  /// Toggles background music (delegates to [toggleMissionMusic]).
  void toggleMusic();

  /// Sets whether background music is enabled (delegates to [setMissionMusicEnabled]).
  Future<void> setMusicEnabled(bool enabled);

  /// Whether mission music is currently muted globally (persisted).
  bool get isMuted;

  /// ValueNotifier that fires when isMuted changes.
  ValueNotifier<bool> get muteNotifier;

  /// Toggles the global mute state and persists to storage.
  void toggleMute();

  /// Whether audio is muted for the current mission session without altering
  /// persistent user settings in SharedPreferences.
  bool get isSessionMuted;

  /// ValueNotifier that fires when session mute state changes.
  ValueNotifier<bool> get sessionMutedNotifier;

  /// Toggles the temporary in-mission session mute state without persisting to preferences.
  void toggleSessionMute();

  /// Sets the temporary in-mission session mute state without persisting to preferences.
  void setSessionMuted(bool muted);

  /// Resets the session mute state to unmuted (typically invoked upon mission exit).
  void resetSessionMute();

  /// Switches the mission audio track on-the-fly during an active mission.
  ///
  /// Normalizes [trackId] to resolve matching track metadata, filenames, or asset paths.
  /// Reuses persistent AudioPlayer instances without disposing or recreating them.
  Future<void> switchMissionTrack(String trackId);

  /// Plays a preview sample of a mission track using a persistent preview player.
  Future<void> playTrackPreview(String trackId);

  /// Stops any currently playing track preview.
  Future<void> stopTrackPreview();

  /// Identifier of the track currently being previewed, or null if stopped.
  ValueNotifier<String?> get previewingTrackNotifier;

  /// Persistent AudioPlayer instance used for track previews.
  AudioPlayer get previewPlayer;

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

/// Production implementation of [AudioService] wrapping persistent [AudioPlayer]s.
class RealAudioService implements AudioService {
  final AudioPlayer _player;
  final AudioPlayer _bridgePlayer;
  final AudioPlayer _previewPlayer;
  static const int _swipePoolSize = 4;
  final List<AudioPlayer> _swipePool = [];
  int _swipePoolIndex = 0;
  final AudioPlayer _deployPlayer;
  final AudioPlayer _victoryPlayer;

  bool _isPlaying = false;
  bool _isMissionPaused = false;
  String? _currentTrack;
  bool _disposed = false;
  bool _isBridgePlaying = false;
  bool _wasBridgePlayingBeforeMission = false;
  bool _isBridgePausedByLifecycle = false;
  bool _isWarmingUp = false;

  /// Dedicated AudioContext configuration ensuring tactical mission audio
  /// continues playing without interruptions when screen is locked or app is backgrounded.
  static final AudioContext missionAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  final ValueNotifier<String?> _previewingTrackNotifier = ValueNotifier<String?>(null);

  @override
  AudioPlayer get previewPlayer => _previewPlayer;

  @override
  ValueNotifier<String?> get previewingTrackNotifier => _previewingTrackNotifier;

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
    MissionAudioTrack(
      id: 'tactical_ambiance_4.mp3',
      title: 'Mission Delta: Dark Synth',
      subtitle: 'Ondes synthétiques sombres & pulsation cyber',
      assetPath: 'tactical_ambiance_4.mp3',
      artist: 'Antti Luode',
      license: 'CC BY 3.0',
    ),
    MissionAudioTrack(
      id: 'tactical_ambiance_5.mp3',
      title: 'Mission Echo: Future City',
      subtitle: 'Électro futuriste & cadence d\'intervention',
      assetPath: 'tactical_ambiance_5.mp3',
      artist: 'Antti Luode',
      license: 'CC BY 3.0',
    ),
    MissionAudioTrack(
      id: 'tactical_ambiance_6.mp3',
      title: 'Mission Foxtrot: Space Dominator Squadron',
      subtitle: 'Assaut spatial & dynamique d\'action critique',
      assetPath: 'tactical_ambiance_6.mp3',
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
        _bridgePlayer = AudioPlayer()
          ..setReleaseMode(ReleaseMode.loop)
          ..setVolume(0.8),
        _previewPlayer = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setVolume(0.85),
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

    _previewPlayer.onPlayerComplete.listen((_) {
      _previewingTrackNotifier.value = null;
    });

    try {
      _player.setAudioContext(missionAudioContext);
    } catch (_) {}

    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Separate App Ambiance vs Mission Music
      if (!prefs.containsKey('appAmbianceEnabled')) {
        await prefs.setBool('appAmbianceEnabled', true);
      }
      _appAmbianceNotifier.value = prefs.getBool('appAmbianceEnabled') ?? true;

      if (!prefs.containsKey('missionMusicEnabled')) {
        final legacyMusic = prefs.getBool('musicEnabled') ??
            !(prefs.getBool('musicMuted') ?? false);
        await prefs.setBool('missionMusicEnabled', legacyMusic);
      }
      final missionMusic = prefs.getBool('missionMusicEnabled') ?? true;
      _missionMusicNotifier.value = missionMusic;
      _muteNotifier.value = !missionMusic;

      if (!prefs.containsKey('sfxEnabled')) {
        await prefs.setBool('sfxEnabled', true);
      }
      _sfxNotifier.value = prefs.getBool('sfxEnabled') ?? true;

      final track = prefs.getString('selectedAudioTrack') ??
          'tactical_ambiance_1.mp3';
      _selectedTrackNotifier.value = track;

      if (_isPlaying) {
        _player.setVolume(_effectiveMusicVolume);
      }
      if (_isBridgePlaying) {
        _bridgePlayer.setVolume(_effectiveBridgeVolume);
      }
    } catch (_) {}

    // Automatically warm up audio buffers in the background at initialization
    await warmUp();
  }

  @override
  Future<void> warmUp() async {
    if (_isWarmingUp || _disposed) return;
    _isWarmingUp = true;
    try {
      // 1. Preload sound files into AudioCache to guarantee instantaneous playback
      await AudioCache.instance.loadPath('audio/swipe.wav');
      await AudioCache.instance.loadPath('audio/deploy.wav');
      await AudioCache.instance.loadPath('audio/victory.wav');
      await AudioCache.instance.loadPath(
        RealAudioService.normalizeAssetPath(AudioService.bridgeAmbianceTrack),
      );
      for (final track in missionTracks) {
        await AudioCache.instance.loadPath(
          RealAudioService.normalizeAssetPath(track.assetPath),
        );
      }

      // 2. Preload SFX low-latency player buffers so first swipe plays with ZERO latency
      for (final p in _swipePool) {
        await p.setSource(AssetSource('audio/swipe.wav'));
      }
      await _deployPlayer.setSource(AssetSource('audio/deploy.wav'));
      await _victoryPlayer.setSource(AssetSource('audio/victory.wav'));

      // 3. Preload bridge ambient track on bridge player
      await _bridgePlayer.setSource(
        AssetSource(RealAudioService.normalizeAssetPath(AudioService.bridgeAmbianceTrack)),
      );

      // 4. Preload selected mission track on persistent mission player for instant start
      final selectedPath = RealAudioService.normalizeAssetPath(_selectedTrackNotifier.value);
      await _player.setSource(AssetSource(selectedPath));
    } catch (_) {
      // In headless test environments, native channels are unavailable
    } finally {
      _isWarmingUp = false;
    }
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isMissionPlaying => _isPlaying;

  @override
  bool get isMissionPaused => _isMissionPaused;

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

  /// Resolves track identifiers, titles, or raw asset paths to registered track filenames.
  static String resolveTrackPath(String trackId) {
    var t = trackId.trim();
    if (t.isEmpty) {
      throw ArgumentError('Track ID cannot be empty');
    }
    for (final track in missionTracks) {
      if (track.id == t ||
          track.assetPath == t ||
          track.title.toLowerCase() == t.toLowerCase()) {
        return track.assetPath;
      }
    }
    if (!t.contains('.')) {
      t = '$t.mp3';
    }
    return t;
  }

  @override
  Future<void> playMissionLoop(String assetPath) async {
    if (_disposed) return;
    final p = RealAudioService.normalizeAssetPath(assetPath);
    if (_isPlaying && _currentTrack == p && !_isMissionPaused) return;

    // Smoothly pause bridge ambiance during mission
    if (_isBridgePlaying) {
      _wasBridgePlayingBeforeMission = true;
      try {
        await _bridgePlayer.pause();
      } catch (_) {}
    }

    _currentTrack = p;
    _isPlaying = true;
    _isMissionPaused = false;
    try {
      await _player.setAudioContext(missionAudioContext);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_effectiveMusicVolume);
      await _player.play(AssetSource(p));
    } catch (_) {}
  }

  @override
  Future<void> pauseMissionLoop() async {
    if (_disposed || !_isPlaying) return;
    _isMissionPaused = true;
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> resumeMissionLoop() async {
    if (_disposed || !_isPlaying) return;
    _isMissionPaused = false;
    if (missionMusicEnabled && !_sessionMutedNotifier.value) {
      try {
        await _player.setVolume(_effectiveMusicVolume);
        await _player.resume();
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _isMissionPaused = false;
    _currentTrack = null;
    resetSessionMute();
    try {
      await _player.stop();
    } catch (_) {}

    // Smoothly resume bridge ambiance if it was active before entering the mission
    if (_wasBridgePlayingBeforeMission) {
      _wasBridgePlayingBeforeMission = false;
      await resumeBridgeLoop();
    }
  }

  @override
  bool get isBridgePlaying => _isBridgePlaying;

  final ValueNotifier<bool> _bridgePlayingNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get bridgePlayingNotifier => _bridgePlayingNotifier;

  @override
  Future<void> playBridgeLoop() async {
    if (_disposed) return;
    _isBridgePausedByLifecycle = false;
    _isBridgePlaying = true;
    _bridgePlayingNotifier.value = true;
    if (_isPlaying) {
      // Mission is active; mark to resume when mission exits
      _wasBridgePlayingBeforeMission = true;
      return;
    }
    if (!appAmbianceEnabled) return;
    try {
      await _bridgePlayer.setReleaseMode(ReleaseMode.loop);
      await _bridgePlayer.setVolume(_effectiveBridgeVolume);
      await _bridgePlayer.play(
        AssetSource(RealAudioService.normalizeAssetPath(AudioService.bridgeAmbianceTrack)),
      );
    } catch (_) {}
  }

  @override
  Future<void> stopBridgeLoop() async {
    if (_disposed) return;
    _isBridgePausedByLifecycle = false;
    _isBridgePlaying = false;
    _wasBridgePlayingBeforeMission = false;
    _bridgePlayingNotifier.value = false;
    try {
      await _bridgePlayer.stop();
    } catch (_) {}
  }

  @override
  Future<void> resumeBridgeLoop() async {
    if (_disposed || _isPlaying) return;
    _isBridgePausedByLifecycle = false;
    _isBridgePlaying = true;
    _bridgePlayingNotifier.value = true;
    if (!appAmbianceEnabled) return;
    try {
      await _bridgePlayer.setVolume(_effectiveBridgeVolume);
      await _bridgePlayer.resume();
    } catch (_) {
      try {
        await _bridgePlayer.play(
          AssetSource(RealAudioService.normalizeAssetPath(AudioService.bridgeAmbianceTrack)),
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> pauseBridgeLoop() async {
    if (_disposed) return;
    if (_isBridgePlaying) {
      _isBridgePausedByLifecycle = true;
      _isBridgePlaying = false;
      _bridgePlayingNotifier.value = false;
      try {
        await _bridgePlayer.pause();
      } catch (_) {}
    }
  }

  @override
  Future<void> pauseAppAmbiance() => pauseBridgeLoop();

  @override
  Future<void> resumeAppAmbiance() async {
    if (_disposed || _isPlaying) return;
    if (!appAmbianceEnabled) return;
    _isBridgePausedByLifecycle = false;
    await resumeBridgeLoop();
  }

  @override
  Future<void> handleAppLifecycleState(AppLifecycleState state, {bool isOnMenu = true}) async {
    if (_disposed) return;
    if (state != AppLifecycleState.resumed) {
      // Backgrounded / Minimized / Inactive: Immediately cut general app ambiance.
      // Mission music continues playing in pocket!
      await pauseAppAmbiance();
    } else {
      // Foreground resumed: resume ambiance only if on menu/home and enabled.
      if (isOnMenu && appAmbianceEnabled && !_isPlaying && _isBridgePausedByLifecycle) {
        await resumeAppAmbiance();
      }
    }
  }

  // Strict separation of state & notifiers
  final ValueNotifier<bool> _appAmbianceNotifier = ValueNotifier<bool>(true);

  @override
  bool get appAmbianceEnabled => _appAmbianceNotifier.value;

  @override
  ValueNotifier<bool> get appAmbianceNotifier => _appAmbianceNotifier;

  @override
  void toggleAppAmbiance() async {
    final next = !_appAmbianceNotifier.value;
    await setAppAmbianceEnabled(next);
  }

  @override
  Future<void> setAppAmbianceEnabled(bool enabled) async {
    if (_appAmbianceNotifier.value == enabled) return;
    _appAmbianceNotifier.value = enabled;
    if (_isBridgePlaying && !_isPlaying) {
      try {
        _bridgePlayer.setVolume(_effectiveBridgeVolume);
        if (!enabled) {
          await _bridgePlayer.pause();
        } else {
          await _bridgePlayer.resume();
        }
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('appAmbianceEnabled', enabled);
    } catch (_) {}
  }

  final ValueNotifier<bool> _missionMusicNotifier = ValueNotifier<bool>(true);

  @override
  bool get missionMusicEnabled => _missionMusicNotifier.value;

  @override
  ValueNotifier<bool> get missionMusicNotifier => _missionMusicNotifier;

  @override
  void toggleMissionMusic() async {
    final next = !_missionMusicNotifier.value;
    await setMissionMusicEnabled(next);
  }

  @override
  Future<void> setMissionMusicEnabled(bool enabled) async {
    if (_missionMusicNotifier.value == enabled) return;
    _missionMusicNotifier.value = enabled;
    _muteNotifier.value = !enabled;
    if (_isPlaying) {
      try {
        _player.setVolume(_effectiveMusicVolume);
        if (!enabled) {
          await _player.pause();
        } else if (!_isMissionPaused && !_sessionMutedNotifier.value) {
          await _player.resume();
        }
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('missionMusicEnabled', enabled);
      await prefs.setBool('musicEnabled', enabled);
      await prefs.setBool('musicMuted', !enabled);
    } catch (_) {}
  }

  // Legacy mappings for backwards-compatibility
  @override
  bool get musicEnabled => missionMusicEnabled;

  @override
  ValueNotifier<bool> get musicEnabledNotifier => _missionMusicNotifier;

  @override
  void toggleMusic() => toggleMissionMusic();

  @override
  Future<void> setMusicEnabled(bool enabled) => setMissionMusicEnabled(enabled);

  @override
  bool get isMuted => _muteNotifier.value;

  final ValueNotifier<bool> _muteNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get muteNotifier => _muteNotifier;

  @override
  void toggleMute() => toggleMissionMusic();

  double get _effectiveMusicVolume {
    if (!missionMusicEnabled) return 0.0;
    if (_sessionMutedNotifier.value || _isMissionPaused) return 0.0;
    return 1.0;
  }

  double get _effectiveBridgeVolume => appAmbianceEnabled ? 0.8 : 0.0;

  @override
  bool get isSessionMuted => _sessionMutedNotifier.value;

  final ValueNotifier<bool> _sessionMutedNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get sessionMutedNotifier => _sessionMutedNotifier;

  @override
  void toggleSessionMute() {
    setSessionMuted(!_sessionMutedNotifier.value);
  }

  @override
  void setSessionMuted(bool muted) {
    if (_sessionMutedNotifier.value == muted) return;
    _sessionMutedNotifier.value = muted;
    if (_isPlaying) {
      if (muted) {
        pauseMissionLoop();
      } else {
        resumeMissionLoop();
      }
    }
  }

  @override
  void resetSessionMute() {
    if (_sessionMutedNotifier.value) {
      _sessionMutedNotifier.value = false;
      if (_isPlaying) {
        resumeMissionLoop();
      }
    }
  }

  @override
  Future<void> switchMissionTrack(String trackId) async {
    if (_disposed) return;
    final resolved = RealAudioService.resolveTrackPath(trackId);
    final normalized = RealAudioService.normalizeAssetPath(resolved);
    _selectedTrackNotifier.value = resolved;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedAudioTrack', resolved);
    } catch (_) {}

    // Persistent player reuse: do NOT dispose or recreate player instances
    if (_isPlaying) {
      _currentTrack = normalized;
      _isMissionPaused = false;
      try {
        await _player.stop();
        await _player.setAudioContext(missionAudioContext);
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(_effectiveMusicVolume);
        await _player.play(AssetSource(normalized));
      } catch (_) {}
    } else {
      // Pre-warm on persistent player so next start is instant
      try {
        await _player.setSource(AssetSource(normalized));
      } catch (_) {}
    }
  }

  @override
  Future<void> playTrackPreview(String trackId) async {
    if (_disposed) return;
    final resolved = RealAudioService.resolveTrackPath(trackId);
    final normalized = RealAudioService.normalizeAssetPath(resolved);
    _previewingTrackNotifier.value = resolved;
    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource(normalized));
    } catch (_) {}
  }

  @override
  Future<void> stopTrackPreview() async {
    if (_disposed) return;
    _previewingTrackNotifier.value = null;
    try {
      await _previewPlayer.stop();
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
    await switchMissionTrack(track);
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
    _isMissionPaused = false;
    _currentTrack = null;
    _isBridgePlaying = false;
    _wasBridgePlayingBeforeMission = false;
    _previewingTrackNotifier.value = null;
    _disposed = true;
    try {
      _player.stop();
      _bridgePlayer.stop();
      _previewPlayer.stop();
      _stopAllSfx();
    } catch (_) {}
  }
}

/// In-memory mock of [AudioService] for headless unit and widget testing.
class MockAudioService implements AudioService {
  bool _isPlaying = false;
  bool _isMissionPaused = false;
  String? _currentTrack;
  bool _disposed = false;
  int playCount = 0;
  int stopCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  final List<String> playedTracks = [];

  // Bridge Ambiance state & telemetry
  bool _isBridgePlaying = false;
  bool _wasBridgePlayingBeforeMission = false;
  int bridgePlayCount = 0;
  int bridgeStopCount = 0;
  int bridgeResumeCount = 0;
  final ValueNotifier<bool> _bridgePlayingNotifier = ValueNotifier<bool>(false);

  // App Ambiance vs Mission Music separate state
  final ValueNotifier<bool> _appAmbianceNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _missionMusicNotifier = ValueNotifier<bool>(true);
  int appAmbianceToggleCount = 0;
  int missionMusicToggleCount = 0;

  // Session Mute state & telemetry
  final ValueNotifier<bool> _sessionMutedNotifier = ValueNotifier<bool>(false);
  int sessionMuteToggleCount = 0;

  // Track preview & switching telemetry
  int switchTrackCount = 0;
  int previewPlayCount = 0;
  int previewStopCount = 0;
  final List<String> switchedTracks = [];
  final ValueNotifier<String?> _previewingTrackNotifier = ValueNotifier<String?>(null);
  AudioPlayer? _previewPlayer;

  // SFX counts
  int swipeCount = 0;
  int deployCount = 0;
  int victoryCount = 0;
  int warmUpCount = 0;

  MockAudioService({AudioPlayer? previewPlayerInstance}) : _previewPlayer = previewPlayerInstance;

  @override
  AudioPlayer get previewPlayer => _previewPlayer ??= AudioPlayer();

  @override
  ValueNotifier<String?> get previewingTrackNotifier => _previewingTrackNotifier;

  @override
  Future<void> warmUp() async {
    warmUpCount++;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isMissionPlaying => _isPlaying;

  @override
  bool get isMissionPaused => _isMissionPaused;

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
    if (_isBridgePlaying) {
      _wasBridgePlayingBeforeMission = true;
      _isBridgePlaying = false;
      _bridgePlayingNotifier.value = false;
    }
    _isPlaying = true;
    _isMissionPaused = false;
    _currentTrack = assetPath;
    playCount++;
    playedTracks.add(assetPath);
  }

  @override
  Future<void> pauseMissionLoop() async {
    if (_disposed || !_isPlaying) return;
    _isMissionPaused = true;
    pauseCount++;
  }

  @override
  Future<void> resumeMissionLoop() async {
    if (_disposed || !_isPlaying) return;
    _isMissionPaused = false;
    resumeCount++;
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _isMissionPaused = false;
    _currentTrack = null;
    stopCount++;
    resetSessionMute();
    if (_wasBridgePlayingBeforeMission) {
      _wasBridgePlayingBeforeMission = false;
      await resumeBridgeLoop();
    }
  }

  @override
  bool get isBridgePlaying => _bridgePlayingNotifier.value;

  @override
  ValueNotifier<bool> get bridgePlayingNotifier => _bridgePlayingNotifier;

  @override
  Future<void> playBridgeLoop() async {
    if (_disposed) return;
    bridgePlayCount++;
    _isBridgePlaying = true;
    _bridgePlayingNotifier.value = true;
    if (_isPlaying) {
      _wasBridgePlayingBeforeMission = true;
    }
  }

  @override
  Future<void> stopBridgeLoop() async {
    if (_disposed) return;
    bridgeStopCount++;
    _isBridgePlaying = false;
    _wasBridgePlayingBeforeMission = false;
    _bridgePlayingNotifier.value = false;
  }

  @override
  Future<void> resumeBridgeLoop() async {
    if (_disposed) return;
    bridgeResumeCount++;
    _isBridgePlaying = true;
    _bridgePlayingNotifier.value = true;
  }

  @override
  Future<void> pauseBridgeLoop() async {
    if (_disposed) return;
    _isBridgePlaying = false;
    _bridgePlayingNotifier.value = false;
  }

  @override
  Future<void> pauseAppAmbiance() => pauseBridgeLoop();

  @override
  Future<void> resumeAppAmbiance() => resumeBridgeLoop();

  @override
  Future<void> handleAppLifecycleState(AppLifecycleState state, {bool isOnMenu = true}) async {
    if (_disposed) return;
    if (state != AppLifecycleState.resumed) {
      await pauseAppAmbiance();
    } else if (isOnMenu && appAmbianceEnabled && !_isPlaying) {
      await resumeAppAmbiance();
    }
  }

  @override
  bool get appAmbianceEnabled => _appAmbianceNotifier.value;

  @override
  ValueNotifier<bool> get appAmbianceNotifier => _appAmbianceNotifier;

  @override
  void toggleAppAmbiance() {
    _appAmbianceNotifier.value = !_appAmbianceNotifier.value;
    appAmbianceToggleCount++;
  }

  @override
  Future<void> setAppAmbianceEnabled(bool enabled) async {
    _appAmbianceNotifier.value = enabled;
  }

  @override
  bool get missionMusicEnabled => _missionMusicNotifier.value;

  @override
  ValueNotifier<bool> get missionMusicNotifier => _missionMusicNotifier;

  @override
  void toggleMissionMusic() {
    _missionMusicNotifier.value = !_missionMusicNotifier.value;
    _muteNotifier.value = !_missionMusicNotifier.value;
    missionMusicToggleCount++;
  }

  @override
  Future<void> setMissionMusicEnabled(bool enabled) async {
    _missionMusicNotifier.value = enabled;
    _muteNotifier.value = !enabled;
  }

  @override
  bool get musicEnabled => _missionMusicNotifier.value;

  @override
  ValueNotifier<bool> get musicEnabledNotifier => _missionMusicNotifier;

  @override
  void toggleMusic() => toggleMissionMusic();

  @override
  Future<void> setMusicEnabled(bool enabled) => setMissionMusicEnabled(enabled);

  @override
  bool get isMuted => _muteNotifier.value;

  final ValueNotifier<bool> _muteNotifier = ValueNotifier<bool>(false);

  @override
  ValueNotifier<bool> get muteNotifier => _muteNotifier;

  @override
  void toggleMute() => toggleMissionMusic();

  @override
  bool get isSessionMuted => _sessionMutedNotifier.value;

  @override
  ValueNotifier<bool> get sessionMutedNotifier => _sessionMutedNotifier;

  @override
  void toggleSessionMute() {
    setSessionMuted(!_sessionMutedNotifier.value);
  }

  @override
  void setSessionMuted(bool muted) {
    _sessionMutedNotifier.value = muted;
    sessionMuteToggleCount++;
    if (_isPlaying) {
      if (muted) {
        pauseMissionLoop();
      } else {
        resumeMissionLoop();
      }
    }
  }

  @override
  void resetSessionMute() {
    _sessionMutedNotifier.value = false;
  }

  @override
  Future<void> switchMissionTrack(String trackId) async {
    final trimmed = trackId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Track ID cannot be empty');
    }
    switchTrackCount++;
    switchedTracks.add(trackId);
    _selectedTrackNotifier.value = trackId;
    if (_isPlaying) {
      await playMissionLoop(trackId);
    }
  }

  @override
  Future<void> playTrackPreview(String trackId) async {
    previewPlayCount++;
    _previewingTrackNotifier.value = trackId;
  }

  @override
  Future<void> stopTrackPreview() async {
    previewStopCount++;
    _previewingTrackNotifier.value = null;
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
    await switchMissionTrack(track);
  }

  @override
  Future<void> playSwipe() async {
    swipeCount++;
  }

  @override
  Future<void> playDeploy() async {
    deployCount++;
  }

  @override
  Future<void> playVictory() async {
    victoryCount++;
  }

  @override
  void dispose() {
    _isPlaying = false;
    _isMissionPaused = false;
    _currentTrack = null;
    _isBridgePlaying = false;
    _wasBridgePlayingBeforeMission = false;
    _bridgePlayingNotifier.value = false;
    _previewingTrackNotifier.value = null;
    _disposed = true;
  }

  /// Resets all mock recording counters and state flags.
  void reset() {
    _isPlaying = false;
    _isMissionPaused = false;
    _currentTrack = null;
    _disposed = false;
    playCount = 0;
    stopCount = 0;
    pauseCount = 0;
    resumeCount = 0;
    playedTracks.clear();

    _sfxNotifier.value = true;
    _muteNotifier.value = false;
    _missionMusicNotifier.value = true;
    _appAmbianceNotifier.value = true;
    appAmbianceToggleCount = 0;
    missionMusicToggleCount = 0;
    _selectedTrackNotifier.value = 'tactical_ambiance_1.mp3';

    _isBridgePlaying = false;
    _wasBridgePlayingBeforeMission = false;
    bridgePlayCount = 0;
    bridgeStopCount = 0;
    bridgeResumeCount = 0;
    _bridgePlayingNotifier.value = false;

    _sessionMutedNotifier.value = false;
    sessionMuteToggleCount = 0;

    switchTrackCount = 0;
    previewPlayCount = 0;
    previewStopCount = 0;
    switchedTracks.clear();
    _previewingTrackNotifier.value = null;

    swipeCount = 0;
    deployCount = 0;
    victoryCount = 0;
    warmUpCount = 0;
  }
}
