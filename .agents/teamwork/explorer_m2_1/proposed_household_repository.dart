import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/room_category.dart';
import 'package:household_stratagem/models/user_profile.dart';

/// Contract for household persistence and tactical mission logging.
abstract class HouseholdRepository {
  /// Retrieves the user profile for [userId], or null if not found.
  Future<UserProfile?> getUserProfile(String userId);

  /// Saves or updates the user profile.
  Future<void> saveUserProfile(UserProfile profile);

  /// Retrieves all configured chores for [userId].
  Future<List<Chore>> getChores(String userId);

  /// Replaces or batch-saves configured chores for [userId].
  Future<void> saveChores(String userId, List<Chore> chores);

  /// Updates or upserts a single chore for [userId].
  Future<void> updateChore(String userId, Chore chore);

  /// Appends an execution log of a completed or attempted cleaning mission.
  Future<void> logMission(String userId, MissionLog log);

  /// Retrieves the mission execution history for [userId].
  Future<List<MissionLog>> getMissionLogs(String userId);
}

/// Production implementation of [HouseholdRepository] persisting to Cloud Firestore.
///
/// Hierarchy:
/// - Profiles: `users/{userId}`
/// - Tasks: `users/{userId}/tasks/{choreId}`
/// - History: `users/{userId}/history/{logId}`
class FirestoreHouseholdRepository implements HouseholdRepository {
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String historyCollection = 'history';

  final FirebaseFirestore _firestore;

  FirestoreHouseholdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (userId.trim().isEmpty) return null;
    final doc =
        await _firestore.collection(usersCollection).doc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserProfile.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    if (profile.userId.trim().isEmpty) {
      throw ArgumentError('UserProfile userId cannot be empty');
    }
    await _firestore
        .collection(usersCollection)
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<Chore>> getChores(String userId) async {
    if (userId.trim().isEmpty) return [];
    final snapshot = await _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(tasksCollection)
        .get();

    return snapshot.docs
        .map((doc) => Chore.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> saveChores(String userId, List<Chore> chores) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    if (chores.isEmpty) return;

    final tasksRef = _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(tasksCollection);

    // Cloud Firestore WriteBatch limit is 500 writes. We chunk into batches of 400.
    const batchSize = 400;
    for (var i = 0; i < chores.length; i += batchSize) {
      final batch = _firestore.batch();
      final end =
          (i + batchSize < chores.length) ? i + batchSize : chores.length;
      final chunk = chores.sublist(i, end);

      for (final chore in chunk) {
        final choreId = chore.id.isNotEmpty ? chore.id : tasksRef.doc().id;
        final docRef = tasksRef.doc(choreId);
        final data = chore.id.isNotEmpty
            ? chore.toMap()
            : chore.copyWith(id: choreId).toMap();
        batch.set(docRef, data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  @override
  Future<void> updateChore(String userId, Chore chore) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    final tasksRef = _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(tasksCollection);

    final choreId = chore.id.isNotEmpty ? chore.id : tasksRef.doc().id;
    final docRef = tasksRef.doc(choreId);
    final data = chore.id.isNotEmpty
        ? chore.toMap()
        : chore.copyWith(id: choreId).toMap();
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> logMission(String userId, MissionLog log) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    final historyRef = _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(historyCollection);

    final docRef =
        log.id.isNotEmpty ? historyRef.doc(log.id) : historyRef.doc();
    final data = log.id.isNotEmpty
        ? log.toMap()
        : log.copyWith(id: docRef.id).toMap();
    await docRef.set(data);
  }

  @override
  Future<List<MissionLog>> getMissionLogs(String userId) async {
    if (userId.trim().isEmpty) return [];
    final snapshot = await _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(historyCollection)
        .get();

    final logs = snapshot.docs
        .map((doc) => MissionLog.fromMap(doc.data(), doc.id))
        .toList();

    // Preserve chronological ordering from earliest to latest completed
    logs.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return logs;
  }
}

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
