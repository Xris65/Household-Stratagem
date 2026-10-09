import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'household_repository.dart';

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
