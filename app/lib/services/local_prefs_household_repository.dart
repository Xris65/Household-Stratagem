import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:household_stratagem/services/household_repository.dart';

class LocalPrefsHouseholdRepository implements HouseholdRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString('profile_$userId');
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromMap(map, userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await _prefs;
    final jsonStr = jsonEncode(profile.toMap());
    await prefs.setString('profile_${profile.userId}', jsonStr);
  }

  @override
  Future<List<Chore>> getChores(String userId) async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString('chores_$userId');
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Chore.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveChores(String userId, List<Chore> chores) async {
    final prefs = await _prefs;
    final list = chores.map((c) => c.toMap()).toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString('chores_$userId', jsonStr);
  }

  @override
  Future<void> updateChore(String userId, Chore chore) async {
    final chores = await getChores(userId);
    final idx = chores.indexWhere((c) => c.id == chore.id);
    if (idx != -1) {
      chores[idx] = chore;
    } else {
      chores.add(chore);
    }
    await saveChores(userId, chores);
  }

  @override
  Future<void> logMission(String userId, MissionLog log) async {
    final logs = await getMissionLogs(userId);
    logs.add(log);
    
    final prefs = await _prefs;
    final list = logs.map((l) => l.toMap()).toList();
    await prefs.setString('logs_$userId', jsonEncode(list));
  }

  @override
  Future<List<MissionLog>> getMissionLogs(String userId) async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString('logs_$userId');
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final logs = list.map((e) => MissionLog.fromMap(e as Map<String, dynamic>)).toList();
      logs.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      return logs;
    } catch (e) {
      return [];
    }
  }
}
