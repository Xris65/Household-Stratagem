import 'dart:async';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/room_category.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'household_repository.dart';

/// In-memory implementation of [HouseholdRepository] for offline demo mode
/// and headless testing without Firebase dependencies.
///
/// Pre-seeded with default 17 tactical chores from [RoomCategory.defaultChores].
class InMemoryHouseholdRepository implements HouseholdRepository {
  final Map<String, UserProfile> _profiles;
  final Map<String, List<Chore>> _chores;
  final Map<String, List<MissionLog>> _logs;

  /// Default 17 seed chores available for new users or demo mode.
  final List<Chore> seedChores;

  /// Whether to automatically populate [seedChores] on first read if empty.
  final bool autoSeed;

  InMemoryHouseholdRepository({
    List<Chore>? seedChores,
    this.autoSeed = false,
    Map<String, UserProfile>? initialProfiles,
    Map<String, List<Chore>>? initialChores,
    Map<String, List<MissionLog>>? initialLogs,
  })  : seedChores =
            seedChores ?? List.unmodifiable(RoomCategory.defaultChores),
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

  /// Manually populates default chores for [userId].
  void seedDefaultsForUser(String userId) {
    _chores[userId] = seedChores.map((c) => c.copyWith()).toList();
  }

  /// Resets all stored memory data.
  void reset() {
    _profiles.clear();
    _chores.clear();
    _logs.clear();
  }

  // Inspection getters for tests
  Map<String, UserProfile> get profiles => Map.unmodifiable(_profiles);
  Map<String, List<Chore>> get allChores => Map.unmodifiable(_chores);
  Map<String, List<MissionLog>> get allLogs => Map.unmodifiable(_logs);
}
