import 'dart:async';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
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
