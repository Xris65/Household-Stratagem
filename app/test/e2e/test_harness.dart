import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Opaque Room Categories for HouseholdStratagem
class E2ERoomCategory {
  static const String cuisine = 'Cuisine';
  static const String salleDeBain = 'Salle de bain';
  static const String salon = 'Salon';
  static const String chambre = 'Chambre';

  static const List<String> allRooms = [
    cuisine,
    salleDeBain,
    salon,
    chambre,
  ];

  static bool isValid(String room) => allRooms.contains(room);
}

/// Opaque Chore Model Contract
class E2EChore {
  final String id;
  final String name;
  final int difficulty; // 1 to 5
  final String room;
  final int periodicityDays;
  final DateTime? lastCompletedAt;
  final List<String>? swipeSequence;
  final bool enabled;

  const E2EChore({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.room,
    required this.periodicityDays,
    this.lastCompletedAt,
    this.swipeSequence,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty,
      'room': room,
      'periodicityDays': periodicityDays,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'swipeSequence': swipeSequence,
      'enabled': enabled,
    };
  }

  factory E2EChore.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['name'] == null) {
      throw ArgumentError('Chore map must contain id and name');
    }
    return E2EChore(
      id: map['id'] as String,
      name: map['name'] as String,
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      room: (map['room'] as String?) ?? E2ERoomCategory.cuisine,
      periodicityDays: (map['periodicityDays'] as num?)?.toInt() ?? 1,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.parse(map['lastCompletedAt'] as String)
          : null,
      swipeSequence: (map['swipeSequence'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }

  E2EChore copyWith({
    String? id,
    String? name,
    int? difficulty,
    String? room,
    int? periodicityDays,
    DateTime? lastCompletedAt,
    List<String>? swipeSequence,
    bool? enabled,
  }) {
    return E2EChore(
      id: id ?? this.id,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      room: room ?? this.room,
      periodicityDays: periodicityDays ?? this.periodicityDays,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      swipeSequence: swipeSequence ?? this.swipeSequence,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is E2EChore &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          difficulty == other.difficulty &&
          room == other.room &&
          periodicityDays == other.periodicityDays &&
          lastCompletedAt == other.lastCompletedAt &&
          enabled == other.enabled;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      difficulty.hashCode ^
      room.hashCode ^
      periodicityDays.hashCode ^
      lastCompletedAt.hashCode ^
      enabled.hashCode;
}

/// Opaque Mission Log Model Contract
class E2EMissionLog {
  final String choreId;
  final DateTime completedAt;
  final bool success;
  final int durationSeconds;

  const E2EMissionLog({
    required this.choreId,
    required this.completedAt,
    required this.success,
    this.durationSeconds = 600,
  });

  Map<String, dynamic> toMap() {
    return {
      'choreId': choreId,
      'completedAt': completedAt.toIso8601String(),
      'success': success,
      'durationSeconds': durationSeconds,
    };
  }

  factory E2EMissionLog.fromMap(Map<String, dynamic> map) {
    return E2EMissionLog(
      choreId: map['choreId'] as String,
      completedAt: DateTime.parse(map['completedAt'] as String),
      success: map['success'] as bool,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 600,
    );
  }
}

/// Opaque User Profile Model Contract
class E2EUserProfile {
  final String userId;
  final String agentName;
  final int level;
  final int credits;
  final int medals;
  final bool onboarded;
  final String preferredAudioTrack;

  const E2EUserProfile({
    required this.userId,
    this.agentName = 'Nettoyeur-1',
    this.level = 1,
    this.credits = 0,
    this.medals = 0,
    this.onboarded = false,
    this.preferredAudioTrack = 'tactical_ambiance_1.mp3',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentName': agentName,
      'level': level,
      'credits': credits,
      'medals': medals,
      'onboarded': onboarded,
      'preferredAudioTrack': preferredAudioTrack,
    };
  }

  factory E2EUserProfile.fromMap(Map<String, dynamic> map) {
    return E2EUserProfile(
      userId: map['userId'] as String,
      agentName: (map['agentName'] as String?) ?? 'Nettoyeur-1',
      level: (map['level'] as num?)?.toInt() ?? 1,
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      medals: (map['medals'] as num?)?.toInt() ?? 0,
      onboarded: (map['onboarded'] as bool?) ?? false,
      preferredAudioTrack:
          (map['preferredAudioTrack'] as String?) ?? 'tactical_ambiance_1.mp3',
    );
  }

  E2EUserProfile copyWith({
    String? userId,
    String? agentName,
    int? level,
    int? credits,
    int? medals,
    bool? onboarded,
    String? preferredAudioTrack,
  }) {
    return E2EUserProfile(
      userId: userId ?? this.userId,
      agentName: agentName ?? this.agentName,
      level: level ?? this.level,
      credits: credits ?? this.credits,
      medals: medals ?? this.medals,
      onboarded: onboarded ?? this.onboarded,
      preferredAudioTrack: preferredAudioTrack ?? this.preferredAudioTrack,
    );
  }
}

/// Targeting Engine Contract & Urgency Formula
class E2ETargetingEngine {
  /// Urgency formula according to PROJECT.md R3:
  /// If never completed: 1000.0 + (difficulty * 10.0)
  /// Else: (overdueRatio * 100.0) + (difficulty * 5.0)
  static double calculateUrgencyScore(E2EChore chore, {DateTime? now}) {
    if (chore.lastCompletedAt == null) {
      return 1000.0 + (chore.difficulty * 10.0);
    }

    final referenceTime = now ?? DateTime.now();
    if (referenceTime.isBefore(chore.lastCompletedAt!)) {
      // Future completion date (clock drift guard) clamped to 0 overdue
      return 0.0 + (chore.difficulty * 5.0);
    }

    final elapsedSeconds =
        referenceTime.difference(chore.lastCompletedAt!).inSeconds;
    final periodicitySeconds = chore.periodicityDays * 86400.0;
    if (periodicitySeconds <= 0) {
      return 1000.0 + (chore.difficulty * 10.0);
    }

    final overdueRatio = elapsedSeconds / periodicitySeconds;
    return (overdueRatio * 100.0) + (chore.difficulty * 5.0);
  }

  /// Selects Top N targets sorted descending by urgency,
  /// breaking ties by difficulty descending, then name ascending.
  static List<E2EChore> getTopTargets(
    List<E2EChore> chores, {
    int count = 3,
    DateTime? now,
  }) {
    final activeChores = chores.where((c) => c.enabled).toList();
    if (activeChores.isEmpty) return [];

    activeChores.sort((a, b) {
      final scoreA = calculateUrgencyScore(a, now: now);
      final scoreB = calculateUrgencyScore(b, now: now);
      if ((scoreA - scoreB).abs() > 0.0001) {
        return scoreB.compareTo(scoreA); // Descending score
      }
      if (a.difficulty != b.difficulty) {
        return b.difficulty.compareTo(a.difficulty); // Descending diff
      }
      return a.name.compareTo(b.name); // Alphabetical name
    });

    final targetCount = count.clamp(0, activeChores.length);
    return activeChores.sublist(0, targetCount);
  }
}

/// Stratagem Engine Contract
class E2EStratagemEngine {
  static const List<String> directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];

  /// Generates 5 to 8 moves sequence based on difficulty:
  /// Diff 1 -> 5 moves
  /// Diff 2 -> 5 moves
  /// Diff 3 -> 6 moves
  /// Diff 4 -> 7 moves
  /// Diff 5+ -> 8 moves
  static List<String> generateSequenceForDifficulty(
    int difficulty, {
    Random? random,
  }) {
    final rng = random ?? Random();
    int length;
    if (difficulty <= 2) {
      length = 5;
    } else if (difficulty == 3) {
      length = 6;
    } else if (difficulty == 4) {
      length = 7;
    } else {
      length = 8;
    }

    // Strict clamp between 5 and 8
    length = length.clamp(5, 8);

    return List.generate(length, (_) => directions[rng.nextInt(directions.length)]);
  }

  /// Step-by-step swipe validation
  static bool isMoveCorrect(
    List<String> targetSequence,
    int currentIndex,
    String move,
  ) {
    if (currentIndex < 0 || currentIndex >= targetSequence.length) {
      return false;
    }
    return targetSequence[currentIndex] == move;
  }
}

/// Opaque Auth Service Contract & In-Memory Implementation
abstract class E2EAuthService {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<String> signInAnonymously();
  Future<String> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
}

class E2EInMemoryAuthService implements E2EAuthService {
  final _controller = StreamController<String?>.broadcast();
  String? _currentUserId;

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
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Email and password must not be empty');
    }
    final uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    _currentUserId = uid;
    _controller.add(uid);
    return uid;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// Opaque Household Repository Contract & In-Memory Implementation
abstract class E2EHouseholdRepository {
  Future<E2EUserProfile?> getUserProfile(String userId);
  Future<void> saveUserProfile(E2EUserProfile profile);
  Future<List<E2EChore>> getChores(String userId);
  Future<void> saveChores(String userId, List<E2EChore> chores);
  Future<void> updateChore(String userId, E2EChore chore);
  Future<void> logMission(String userId, E2EMissionLog log);
  Future<List<E2EMissionLog>> getMissionLogs(String userId);
}

class E2EInMemoryHouseholdRepository implements E2EHouseholdRepository {
  final Map<String, E2EUserProfile> _profiles = {};
  final Map<String, List<E2EChore>> _chores = {};
  final Map<String, List<E2EMissionLog>> _logs = {};

  @override
  Future<E2EUserProfile?> getUserProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveUserProfile(E2EUserProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  @override
  Future<List<E2EChore>> getChores(String userId) async {
    return List<E2EChore>.from(_chores[userId] ?? []);
  }

  @override
  Future<void> saveChores(String userId, List<E2EChore> chores) async {
    _chores[userId] = List.from(chores);
  }

  @override
  Future<void> updateChore(String userId, E2EChore chore) async {
    final list = _chores[userId] ?? [];
    final idx = list.indexWhere((c) => c.id == chore.id);
    if (idx != -1) {
      list[idx] = chore;
    } else {
      list.add(chore);
    }
    _chores[userId] = list;
  }

  @override
  Future<void> logMission(String userId, E2EMissionLog log) async {
    _logs.putIfAbsent(userId, () => []).add(log);
  }

  @override
  Future<List<E2EMissionLog>> getMissionLogs(String userId) async {
    return List<E2EMissionLog>.from(_logs[userId] ?? []);
  }

  void reset() {
    _profiles.clear();
    _chores.clear();
    _logs.clear();
  }
}

/// Opaque Audio Service Contract & Mock Implementation
abstract class E2EAudioService {
  bool get isPlaying;
  String? get currentTrack;
  Future<void> playMissionLoop(String assetPath);
  Future<void> stop();
  void dispose();
}

class E2EMockAudioService implements E2EAudioService {
  bool _isPlaying = false;
  String? _currentTrack;
  bool _disposed = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentTrack => _currentTrack;

  @override
  Future<void> playMissionLoop(String assetPath) async {
    if (_disposed) throw StateError('AudioService is disposed');
    if (assetPath.trim().isEmpty) {
      throw ArgumentError('Asset path cannot be empty');
    }
    _isPlaying = true;
    _currentTrack = assetPath;
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _isPlaying = false;
    _currentTrack = null;
  }

  @override
  void dispose() {
    _isPlaying = false;
    _currentTrack = null;
    _disposed = true;
  }
}

/// Default Predefined Catalogue (17 Chores across 4 Rooms)
class E2EPredefinedCatalogue {
  static List<E2EChore> getDefault17Chores() {
    return [
      // Cuisine (5 chores)
      E2EChore(
        id: 'c1',
        name: 'Nettoyer les plaques & plan de travail',
        difficulty: 2,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        swipeSequence: ['UP', 'RIGHT', 'DOWN', 'DOWN', 'RIGHT'],
      ),
      E2EChore(
        id: 'c2',
        name: 'Vider et nettoyer l\'évier',
        difficulty: 1,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        swipeSequence: ['DOWN', 'DOWN', 'UP', 'RIGHT', 'LEFT'],
      ),
      E2EChore(
        id: 'c3',
        name: 'Sortir les poubelles & tri sélectif',
        difficulty: 1,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 2,
        swipeSequence: ['LEFT', 'DOWN', 'RIGHT', 'UP', 'UP'],
      ),
      E2EChore(
        id: 'c4',
        name: 'Nettoyer le micro-ondes & four',
        difficulty: 3,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 7,
        swipeSequence: ['UP', 'UP', 'RIGHT', 'DOWN', 'LEFT', 'UP'],
      ),
      E2EChore(
        id: 'c5',
        name: 'Lessiver le sol de la cuisine',
        difficulty: 3,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 4,
        swipeSequence: ['DOWN', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN'],
      ),

      // Salle de bain (4 chores)
      E2EChore(
        id: 'b1',
        name: 'Nettoyer le lavabo et le miroir',
        difficulty: 2,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 3,
        swipeSequence: ['UP', 'LEFT', 'DOWN', 'RIGHT', 'UP'],
      ),
      E2EChore(
        id: 'b2',
        name: 'Détartrer la douche / baignoire',
        difficulty: 4,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 7,
        swipeSequence: ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN'],
      ),
      E2EChore(
        id: 'b3',
        name: 'Désinfecter les toilettes (WC)',
        difficulty: 3,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 3,
        swipeSequence: ['DOWN', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'],
      ),
      E2EChore(
        id: 'b4',
        name: 'Laver le carrelage et tapis de bain',
        difficulty: 3,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 7,
        swipeSequence: ['LEFT', 'RIGHT', 'DOWN', 'DOWN', 'UP', 'UP'],
      ),

      // Salon (4 chores)
      E2EChore(
        id: 's1',
        name: 'Passer l\'aspirateur',
        difficulty: 2,
        room: E2ERoomCategory.salon,
        periodicityDays: 3,
        swipeSequence: ['UP', 'DOWN', 'UP', 'DOWN', 'RIGHT'],
      ),
      E2EChore(
        id: 's2',
        name: 'Dépoussiérer les meubles et TV',
        difficulty: 2,
        room: E2ERoomCategory.salon,
        periodicityDays: 7,
        swipeSequence: ['RIGHT', 'LEFT', 'UP', 'UP', 'DOWN', 'RIGHT'],
      ),
      E2EChore(
        id: 's3',
        name: 'Nettoyer et ranger la table basse',
        difficulty: 1,
        room: E2ERoomCategory.salon,
        periodicityDays: 2,
        swipeSequence: ['DOWN', 'RIGHT', 'UP', 'LEFT', 'DOWN'],
      ),
      E2EChore(
        id: 's4',
        name: 'Nettoyer les baies vitrées / fenêtres',
        difficulty: 4,
        room: E2ERoomCategory.salon,
        periodicityDays: 14,
        swipeSequence: ['UP', 'UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'RIGHT'],
      ),

      // Chambre (4 chores)
      E2EChore(
        id: 'ch1',
        name: 'Changer les draps et taies',
        difficulty: 3,
        room: E2ERoomCategory.chambre,
        periodicityDays: 7,
        swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'UP'],
      ),
      E2EChore(
        id: 'ch2',
        name: 'Aérer et faire le lit',
        difficulty: 1,
        room: E2ERoomCategory.chambre,
        periodicityDays: 1,
        swipeSequence: ['UP', 'UP', 'RIGHT', 'LEFT', 'DOWN'],
      ),
      E2EChore(
        id: 'ch3',
        name: 'Aspirer sous le lit et recoins',
        difficulty: 2,
        room: E2ERoomCategory.chambre,
        periodicityDays: 7,
        swipeSequence: ['DOWN', 'LEFT', 'RIGHT', 'DOWN', 'UP', 'UP'],
      ),
      E2EChore(
        id: 'ch4',
        name: 'Trier le linge et ranger penderie',
        difficulty: 2,
        room: E2ERoomCategory.chambre,
        periodicityDays: 3,
        swipeSequence: ['LEFT', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'],
      ),
    ];
  }
}

/// Mil-Tech Dark Tactical Theme Tokens
class E2EMilTechColors {
  static const Color backgroundBlack = Color(0xFF0B0E14);
  static const Color panelDark = Color(0xFF141922);
  static const Color panelBorder = Color(0xFF263040);
  static const Color panelBevel = Color(0xFF333E50);

  // Neon Tactical Accents
  static const Color neonAmber = Color(0xFFFFA500);
  static const Color neonYellow = Color(0xFFFFCC00);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonRed = Color(0xFFFF1744);

  // Text & Neutrals
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
}

/// Strict Vocabulary Purge Validator
class E2ELexiconValidator {
  static const List<String> forbiddenTerms = [
    'squad',
    'escouade',
    'automaton',
    'arsenal',
    'helldiver',
    'orbital strike',
    'heavy assault',
    'artillery',
  ];

  static bool containsForbiddenTerms(String text) {
    final lower = text.toLowerCase();
    for (final term in forbiddenTerms) {
      if (lower.contains(term)) {
        return true;
      }
    }
    return false;
  }

  static List<String> findViolations(String text) {
    final lower = text.toLowerCase();
    final violations = <String>[];
    for (final term in forbiddenTerms) {
      if (lower.contains(term)) {
        violations.add(term);
      }
    }
    return violations;
  }
}

/// Complete End-to-End Application Harness
class E2EAppHarness {
  final E2EInMemoryAuthService authService = E2EInMemoryAuthService();
  final E2EInMemoryHouseholdRepository repository =
      E2EInMemoryHouseholdRepository();
  final E2EMockAudioService audioService = E2EMockAudioService();

  String? currentUserId;
  E2EUserProfile? currentProfile;
  List<E2EChore> currentChores = [];

  // Active mission state
  E2EChore? activeChore;
  List<String> targetSequence = [];
  int currentSwipeIndex = 0;
  int timerSecondsRemaining = 600;
  bool isMissionActive = false;

  void reset() {
    currentUserId = null;
    currentProfile = null;
    currentChores = [];
    activeChore = null;
    targetSequence = [];
    currentSwipeIndex = 0;
    timerSecondsRemaining = 600;
    isMissionActive = false;
    authService.signOut();
    repository.reset();
    audioService.stop();
  }

  Future<void> signInAnonymous() async {
    currentUserId = await authService.signInAnonymously();
    currentProfile = await repository.getUserProfile(currentUserId!);
    if (currentProfile == null) {
      currentProfile = E2EUserProfile(
        userId: currentUserId!,
        agentName: 'Nettoyeur-1',
        level: 1,
        credits: 0,
        medals: 0,
        onboarded: false,
      );
      await repository.saveUserProfile(currentProfile!);
    }
    currentChores = await repository.getChores(currentUserId!);
  }

  Future<void> submitOnboarding(List<E2EChore> customizedChores) async {
    if (currentUserId == null) throw StateError('User not logged in');

    // Rule: At least 1 active chore per room
    for (final room in E2ERoomCategory.allRooms) {
      final hasActive =
          customizedChores.any((c) => c.room == room && c.enabled);
      if (!hasActive) {
        throw ArgumentError('Room $room must have at least 1 enabled chore');
      }
    }

    currentChores = customizedChores;
    await repository.saveChores(currentUserId!, customizedChores);

    currentProfile = currentProfile!.copyWith(onboarded: true);
    await repository.saveUserProfile(currentProfile!);
  }

  List<E2EChore> getTopUrgentTargets({DateTime? now}) {
    return E2ETargetingEngine.getTopTargets(
      currentChores,
      count: 3,
      now: now,
    );
  }

  Future<void> startMission(E2EChore chore) async {
    activeChore = chore;
    targetSequence = chore.swipeSequence ??
        E2EStratagemEngine.generateSequenceForDifficulty(chore.difficulty);
    currentSwipeIndex = 0;
    timerSecondsRemaining = 600;
    isMissionActive = true;
  }

  bool submitSwipe(String direction) {
    if (!isMissionActive) throw StateError('No active mission');
    final isCorrect = E2EStratagemEngine.isMoveCorrect(
      targetSequence,
      currentSwipeIndex,
      direction,
    );

    if (isCorrect) {
      currentSwipeIndex++;
      if (currentSwipeIndex == targetSequence.length) {
        // Unlocked! Start audio pressure
        audioService.playMissionLoop(
          currentProfile?.preferredAudioTrack ?? 'tactical_ambiance_1.mp3',
        );
      }
      return true;
    } else {
      // Reset input buffer
      currentSwipeIndex = 0;
      return false;
    }
  }

  bool isStratagemUnlocked() {
    return isMissionActive &&
        targetSequence.isNotEmpty &&
        currentSwipeIndex >= targetSequence.length;
  }

  void tickTimer(int seconds) {
    if (!isMissionActive) return;
    timerSecondsRemaining = (timerSecondsRemaining - seconds).clamp(0, 600);
    if (timerSecondsRemaining == 0) {
      audioService.stop();
    }
  }

  Future<void> validateMission({DateTime? completionTime}) async {
    if (!isMissionActive || activeChore == null) {
      throw StateError('Cannot validate inactive mission');
    }

    await audioService.stop();

    final now = completionTime ?? DateTime.now();
    final uid = currentUserId ?? 'guest_user';
    final updatedChore = activeChore!.copyWith(lastCompletedAt: now);
    await repository.updateChore(uid, updatedChore);

    final log = E2EMissionLog(
      choreId: activeChore!.id,
      completedAt: now,
      success: true,
      durationSeconds: 600 - timerSecondsRemaining,
    );
    await repository.logMission(uid, log);

    // Update profile credits & medals
    final curProfile = currentProfile ?? E2EUserProfile(userId: uid);
    final newCredits = curProfile.credits + 100 * activeChore!.difficulty;
    final newMedals = curProfile.medals + 1;
    final newLevel = 1 + (newCredits ~/ 500);

    currentProfile = curProfile.copyWith(
      credits: newCredits,
      medals: newMedals,
      level: newLevel,
    );
    await repository.saveUserProfile(currentProfile!);

    // Refresh local chore list
    currentChores = await repository.getChores(uid);

    isMissionActive = false;
    activeChore = null;
    currentSwipeIndex = 0;
  }

  Future<void> abortMission() async {
    await audioService.stop();
    isMissionActive = false;
    activeChore = null;
    currentSwipeIndex = 0;
  }
}
