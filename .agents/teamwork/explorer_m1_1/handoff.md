# Handoff Report — Explorer M1-1: Domain Models & Serialization Design

**Author**: Explorer M1-1 (`explorer_m1_1`)  
**Working Directory**: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m1_1`  
**Recipient**: orchestrator (`275b51ec-7572-45ca-88b1-d6944bed4ad2`)  
**Target Milestone**: M1 (Core Domain, Engines & Test Baseline)

---

## 1. Observation

### 1.1 Existing Codebase & Models
1. **`app/lib/models.dart`** (lines 1–16 verbatim):
   ```dart
   class Chore {
     final String id;
     final String name;
     final int difficulty;

     Chore({required this.id, required this.name, required this.difficulty});
   }

   class MissionLog {
     final String choreId;
     final DateTime completedAt;
     final bool success;

     MissionLog({required this.choreId, required this.completedAt, required this.success});
   }
   ```
   - Lacks fields: `room`, `periodicityDays`, `lastCompletedAt`, `stratagemSequence`, `isDefault` on `Chore`.
   - Lacks fields: `id`, `choreName`, `room`, `durationSeconds` on `MissionLog`.
   - Lacks `UserProfile` model completely.
   - Lacks `RoomCategory` model and predefined chores catalogue completely.
   - Missing all serialization methods (`toMap()`, `fromMap()`, `copyWith()`).

2. **Existing Callers of `models.dart`**:
   - `grep_search` across `app/` found `app/lib/targeting_engine.dart` (lines 1, 4–9 verbatim):
     ```dart
     import 'models.dart';

     class TargetingEngine {
       List<Chore> getAvailableTargets() {
         return [
           Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3),
           Chore(id: '2', name: 'Sortir les poubelles', difficulty: 1),
           Chore(id: '3', name: 'Passer l\'aspirateur', difficulty: 2),
         ];
       }
     }
     ```
   - Any modification to `Chore`'s constructor that makes new fields mandatory (`required`) would break compilation in `app/lib/targeting_engine.dart`.

3. **Specification Documents**:
   - `PROJECT.md` line 15: Models required: `Chore`, `MissionLog`, `UserProfile`, `RoomCategory`.
   - `PROJECT.md` line 36: "4 rooms (Cuisine, Salle de bain, Salon, Chambre) with 17 predefined chores and default periodicities".
   - `PROJECT.md` lines 119–123: Target layout:
     ```
     lib/
     └── models/
         ├── chore.dart
         ├── mission_log.dart
         ├── user_profile.dart
         └── room_category.dart
     ```
   - `ORIGINAL_REQUEST.md` R1 & R2: Firebase Auth and Firestore persistence for user profiles, chore catalogue (periodicity), and mission history. 4 rooms: Cuisine, Salle de bain, Salon, Chambre.

---

## 2. Logic Chain

1. **Architecture Decomposition (Ref 1.1, 1.3)**:
   - Rather than keeping an unwieldy single file or breaking existing file paths, the domain layer must follow standard modular Dart architecture:
     - `app/lib/models/chore.dart`
     - `app/lib/models/mission_log.dart`
     - `app/lib/models/user_profile.dart`
     - `app/lib/models/room_category.dart`
   - To guarantee 100% backwards compatibility with any existing imports (`import 'models.dart';` or `import 'package:household_stratagem/models.dart';`), `app/lib/models.dart` must act as an export barrel file:
     ```dart
     export 'models/chore.dart';
     export 'models/mission_log.dart';
     export 'models/user_profile.dart';
     export 'models/room_category.dart';
     ```

2. **Constructor Backwards Compatibility (Ref 1.1, 1.2)**:
   - `Chore`'s constructor must retain `required id`, `required name`, and `required difficulty`.
   - All newly added fields must provide sensible default values:
     - `room = 'Cuisine'` (or `RoomCategory.cuisine`)
     - `periodicityDays = 7`
     - `lastCompletedAt = null`
     - `stratagemSequence = const []`
     - `isDefault = false`
   - This ensures existing instantiations like `Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3)` compile seamlessly without breaking existing engine code.
   - Similarly for `MissionLog`: `id = ''`, `choreName = ''`, `room = ''`, `durationSeconds = 600`, `success = true` ensures legacy calls `MissionLog(choreId: '...', completedAt: ..., success: true)` continue to work.

3. **Decoupled & Resilient Firestore Serialization (Ref 1.3)**:
   - Keeping domain models independent of Flutter platform plugins (`cloud_firestore`) enables pure Dart unit testing without mock plugin channel registration overhead.
   - A multi-format timestamp parser `_parseDateTime(dynamic value)` is embedded in each model:
     - Handles `DateTime` directly.
     - Handles `String` (ISO-8601 strings, e.g., `'2026-10-04T12:00:00.000Z'`).
     - Handles `int` (epoch milliseconds).
     - Handles runtime `Timestamp` objects (from `cloud_firestore`) via safe dynamic invocation `(value as dynamic).toDate()`.
     - Returns `null` safely if null or unrecognized.
   - `stratagemSequence` is safely cast from `List<dynamic>?` to `List<String>` preventing `TypeError` on Firestore deserialization.
   - Optional document ID override `[String? id]` in `fromMap(map, [id])` allows parsing snapshots where ID is stored on `DocumentSnapshot.id`.

4. **17 Predefined Chores Catalogue (Ref 1.3)**:
   - R2 and Feature 7 mandate 17 predefined chores across the 4 rooms:
     - **Cuisine (5)**: Dégraissage four & plaques (diff 3, 7d), Nettoyer évier & plan de travail (diff 2, 2d), Sortir les poubelles & tri (diff 1, 1d), Détartrer la cafetière (diff 2, 14d), Nettoyage intérieur du réfrigérateur (diff 4, 30d).
     - **Salle de bain (4)**: Détartrage douche & robinetterie (diff 4, 7d), Nettoyer lavabo & miroir (diff 2, 3d), Désinfection sanitaires & WC (diff 3, 2d), Laver tapis de bain & serviettes (diff 1, 7d).
     - **Salon (4)**: Passer l'aspirateur & tapis (diff 2, 3d), Dépoussiérer meubles & étagères (diff 2, 7d), Laver les vitres & baies (diff 4, 30d), Nettoyer & aérer le canapé (diff 3, 14d).
     - **Chambre (4)**: Changer draps & housses de couette (diff 2, 7d), Aspiration & lavage du sol (diff 2, 4d), Rangement & tri de la penderie (diff 3, 14d), Dépoussiérer tables de chevet & lampes (diff 1, 7d).
   - All 17 chores feature valid dynamic swipe sequences conforming to R3 (length between 5 and 8 moves, only directions `'UP'`, `'DOWN'`, `'LEFT'`, `'RIGHT'`).

5. **Value Equality & Testability**:
   - Explicit `operator ==` and `hashCode` implementations on all models enable direct assertion in unit tests (`expect(restored, equals(original))`) without external package dependencies.

---

## 3. Caveats

- **No live Firestore plugin dependency in domain models**: The models deliberately serialize dates as ISO-8601 strings in `toMap()` while accepting both ISO-8601 strings and Firestore `Timestamp` objects in `fromMap()`. If the repository layer (Milestone M2) prefers writing native Firestore `Timestamp` objects into Firestore documents, it can wrap dates with `Timestamp.fromDate(...)` at the repository layer.
- **Pure Dart metadata**: `RoomMetadata` uses an `iconKey: String` (e.g. `'kitchen'`, `'bathtub'`, `'weekend'`, `'bed'`) rather than importing Flutter's `IconData`. The presentation layer widgets (Milestone M4) will map these keys to Cupertino or Material icons.

---

## 4. Conclusion & Implementation Artifacts

All required production-grade Dart code files have been designed and placed in the explorer's working directory ready for Worker implementation:

### 4.1 File Inventory for Worker

| Target File in `app/` | Source Specification File | Role |
|---|---|---|
| `app/lib/models/chore.dart` | `.agents/teamwork/explorer_m1_1/proposed_chore.dart` | Complete `Chore` model with `toMap`, `fromMap`, `copyWith`, `==`, `hashCode` |
| `app/lib/models/mission_log.dart` | `.agents/teamwork/explorer_m1_1/proposed_mission_log.dart` | Complete `MissionLog` model |
| `app/lib/models/user_profile.dart` | `.agents/teamwork/explorer_m1_1/proposed_user_profile.dart` | Complete `UserProfile` model |
| `app/lib/models/room_category.dart` | `.agents/teamwork/explorer_m1_1/proposed_room_category.dart` | 4 rooms constants, metadata, 17 predefined chores |
| `app/lib/models.dart` | `.agents/teamwork/explorer_m1_1/proposed_models.dart` | Re-export barrel file for backwards compatibility |
| `app/test/unit/models_test.dart` | `.agents/teamwork/explorer_m1_1/proposed_models_test.dart` | Comprehensive unit test suite (16 tests covering all models) |

### 4.2 Exact Source Code Designs

#### `app/lib/models/chore.dart`
```dart
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Represents a household cleaning task (chore) with tactical stratagem attributes.
class Chore {
  final String id;
  final String name;
  final String room;
  final int difficulty;
  final int periodicityDays;
  final DateTime? lastCompletedAt;
  final List<String> stratagemSequence;
  final bool isDefault;

  Chore({
    required this.id,
    required this.name,
    this.room = 'Cuisine',
    required this.difficulty,
    this.periodicityDays = 7,
    this.lastCompletedAt,
    this.stratagemSequence = const [],
    this.isDefault = false,
  });

  /// Factory constructor to deserialize from a Map (e.g. from Firestore or JSON).
  factory Chore.fromMap(Map<String, dynamic> map, [String? id]) {
    return Chore(
      id: id ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      room: map['room']?.toString() ?? 'Cuisine',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      periodicityDays: (map['periodicityDays'] as num?)?.toInt() ?? 7,
      lastCompletedAt: _parseDateTime(map['lastCompletedAt']),
      stratagemSequence: (map['stratagemSequence'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  /// Serializes the chore to a Map suitable for Firestore or JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'room': room,
      'difficulty': difficulty,
      'periodicityDays': periodicityDays,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'stratagemSequence': List<String>.from(stratagemSequence),
      'isDefault': isDefault,
    };
  }

  /// Creates a copy of this chore with modified fields.
  /// Set [clearLastCompletedAt] to true to reset [lastCompletedAt] to null.
  Chore copyWith({
    String? id,
    String? name,
    String? room,
    int? difficulty,
    int? periodicityDays,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    List<String>? stratagemSequence,
    bool? isDefault,
  }) {
    return Chore(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      difficulty: difficulty ?? this.difficulty,
      periodicityDays: periodicityDays ?? this.periodicityDays,
      lastCompletedAt: clearLastCompletedAt
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      stratagemSequence: stratagemSequence ?? this.stratagemSequence,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chore &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          room == other.room &&
          difficulty == other.difficulty &&
          periodicityDays == other.periodicityDays &&
          lastCompletedAt == other.lastCompletedAt &&
          _listEquals(stratagemSequence, other.stratagemSequence) &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        room,
        difficulty,
        periodicityDays,
        lastCompletedAt,
        Object.hashAll(stratagemSequence),
        isDefault,
      );

  @override
  String toString() {
    return 'Chore(id: $id, name: "$name", room: "$room", difficulty: $difficulty, '
        'periodicityDays: $periodicityDays, lastCompletedAt: $lastCompletedAt, '
        'stratagemSequence: $stratagemSequence, isDefault: $isDefault)';
  }
}
```

#### `app/lib/models/mission_log.dart`
```dart
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

/// Represents the execution log of a completed or attempted cleaning mission.
class MissionLog {
  final String id;
  final String choreId;
  final String choreName;
  final String room;
  final DateTime completedAt;
  final int durationSeconds;
  final bool success;

  MissionLog({
    this.id = '',
    required this.choreId,
    this.choreName = '',
    this.room = '',
    required this.completedAt,
    this.durationSeconds = 600,
    this.success = true,
  });

  /// Factory constructor to deserialize from a Map (e.g. from Firestore or JSON).
  factory MissionLog.fromMap(Map<String, dynamic> map, [String? id]) {
    return MissionLog(
      id: id ?? map['id']?.toString() ?? '',
      choreId: map['choreId']?.toString() ?? '',
      choreName: map['choreName']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      completedAt: _parseDateTime(map['completedAt']) ?? DateTime.now(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 600,
      success: map['success'] as bool? ?? true,
    );
  }

  /// Serializes the mission log to a Map suitable for Firestore or JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'choreId': choreId,
      'choreName': choreName,
      'room': room,
      'completedAt': completedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'success': success,
    };
  }

  /// Creates a copy of this mission log with modified fields.
  MissionLog copyWith({
    String? id,
    String? choreId,
    String? choreName,
    String? room,
    DateTime? completedAt,
    int? durationSeconds,
    bool? success,
  }) {
    return MissionLog(
      id: id ?? this.id,
      choreId: choreId ?? this.choreId,
      choreName: choreName ?? this.choreName,
      room: room ?? this.room,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      success: success ?? this.success,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          choreId == other.choreId &&
          choreName == other.choreName &&
          room == other.room &&
          completedAt == other.completedAt &&
          durationSeconds == other.durationSeconds &&
          success == other.success;

  @override
  int get hashCode => Object.hash(
        id,
        choreId,
        choreName,
        room,
        completedAt,
        durationSeconds,
        success,
      );

  @override
  String toString() {
    return 'MissionLog(id: $id, choreId: "$choreId", choreName: "$choreName", '
        'room: "$room", completedAt: $completedAt, durationSeconds: $durationSeconds, '
        'success: $success)';
  }
}
```

#### `app/lib/models/user_profile.dart`
```dart
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

/// Represents the tactical user profile stored in Firestore (`users/{userId}`).
class UserProfile {
  final String userId;
  final String? email;
  final bool isOnboarded;
  final String selectedAudioTrack;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    this.email,
    this.isOnboarded = false,
    this.selectedAudioTrack = 'tactical_ambiance_1.mp3',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory constructor to deserialize from a Map (e.g. from Firestore or JSON).
  factory UserProfile.fromMap(Map<String, dynamic> map, [String? userId]) {
    return UserProfile(
      userId: userId ?? map['userId']?.toString() ?? '',
      email: map['email']?.toString(),
      isOnboarded: map['isOnboarded'] as bool? ?? false,
      selectedAudioTrack: map['selectedAudioTrack']?.toString() ?? 'tactical_ambiance_1.mp3',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Serializes the profile to a Map suitable for Firestore or JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'isOnboarded': isOnboarded,
      'selectedAudioTrack': selectedAudioTrack,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this user profile with modified fields.
  UserProfile copyWith({
    String? userId,
    String? email,
    bool? isOnboarded,
    String? selectedAudioTrack,
    DateTime? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          isOnboarded == other.isOnboarded &&
          selectedAudioTrack == other.selectedAudioTrack &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        userId,
        email,
        isOnboarded,
        selectedAudioTrack,
        createdAt,
      );

  @override
  String toString() {
    return 'UserProfile(userId: "$userId", email: "$email", isOnboarded: $isOnboarded, '
        'selectedAudioTrack: "$selectedAudioTrack", createdAt: $createdAt)';
  }
}
```

#### `app/lib/models/room_category.dart`
```dart
import 'chore.dart';

/// Metadata for a room category in the household tactical map.
class RoomMetadata {
  final String name;
  final String description;
  final String iconKey;
  final int defaultTaskCount;

  const RoomMetadata({
    required this.name,
    required this.description,
    required this.iconKey,
    required this.defaultTaskCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMetadata &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          iconKey == other.iconKey &&
          defaultTaskCount == other.defaultTaskCount;

  @override
  int get hashCode => Object.hash(name, description, iconKey, defaultTaskCount);

  @override
  String toString() => 'RoomMetadata(name: "$name", iconKey: "$iconKey")';
}

/// Constants, metadata and default chore catalogue for the 4 core household rooms.
class RoomCategory {
  static const String cuisine = 'Cuisine';
  static const String salleDeBain = 'Salle de bain';
  static const String salon = 'Salon';
  static const String chambre = 'Chambre';

  /// The 4 mandatory room categories defined in project specifications.
  static const List<String> all = [
    cuisine,
    salleDeBain,
    salon,
    chambre,
  ];

  /// Alias for [all].
  static const List<String> rooms = all;

  /// Room metadata definitions (tactical cleaning theme).
  static const Map<String, RoomMetadata> metadata = {
    cuisine: RoomMetadata(
      name: cuisine,
      description: 'Dégraissage, désinfection et gestion des résidus alimentaires',
      iconKey: 'kitchen',
      defaultTaskCount: 5,
    ),
    salleDeBain: RoomMetadata(
      name: salleDeBain,
      description: 'Détartrage, assainissement et élimination de l\'humidité',
      iconKey: 'bathtub',
      defaultTaskCount: 4,
    ),
    salon: RoomMetadata(
      name: salon,
      description: 'Aspiration, dépoussiérage et maintien du confort tactique',
      iconKey: 'weekend',
      defaultTaskCount: 4,
    ),
    chambre: RoomMetadata(
      name: chambre,
      description: 'Aération, renouvellement des textiles et assainissement',
      iconKey: 'bed',
      defaultTaskCount: 4,
    ),
  };

  /// Returns metadata for the given room, or null if not recognized.
  static RoomMetadata? getMetadata(String room) => metadata[room];

  /// Validates whether a room string belongs to the official 4 categories.
  static bool isValid(String room) => all.contains(room);

  /// Catalogue of 17 predefined default chores with dynamic 5-8 swipe sequences.
  static List<Chore> get defaultChores => [
        // --- CUISINE (5 tâches) ---
        Chore(
          id: 'cuisine_degraissage_four',
          name: 'Dégraissage four & plaques',
          room: cuisine,
          difficulty: 3,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'RIGHT', 'DOWN', 'DOWN', 'LEFT'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_nettoyage_evier',
          name: 'Nettoyer évier & plan de travail',
          room: cuisine,
          difficulty: 2,
          periodicityDays: 2,
          stratagemSequence: ['LEFT', 'RIGHT', 'LEFT', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_sortir_poubelles',
          name: 'Sortir les poubelles & tri',
          room: cuisine,
          difficulty: 1,
          periodicityDays: 1,
          stratagemSequence: ['DOWN', 'DOWN', 'UP', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_detartrage_cafetiere',
          name: 'Détartrer la cafetière',
          room: cuisine,
          difficulty: 2,
          periodicityDays: 14,
          stratagemSequence: ['UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_refrigerateur',
          name: 'Nettoyage intérieur du réfrigérateur',
          room: cuisine,
          difficulty: 4,
          periodicityDays: 30,
          stratagemSequence: ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN'],
          isDefault: true,
        ),

        // --- SALLE DE BAIN (4 tâches) ---
        Chore(
          id: 'sdb_detartrage_douche',
          name: 'Détartrage douche & robinetterie',
          room: salleDeBain,
          difficulty: 4,
          periodicityDays: 7,
          stratagemSequence: ['DOWN', 'UP', 'LEFT', 'RIGHT', 'DOWN', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_lavabo_miroir',
          name: 'Nettoyer lavabo & miroir',
          room: salleDeBain,
          difficulty: 2,
          periodicityDays: 3,
          stratagemSequence: ['LEFT', 'UP', 'RIGHT', 'DOWN', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_desinfection_wc',
          name: 'Désinfection sanitaires & WC',
          room: salleDeBain,
          difficulty: 3,
          periodicityDays: 2,
          stratagemSequence: ['DOWN', 'DOWN', 'LEFT', 'RIGHT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_tapis_serviettes',
          name: 'Laver tapis de bain & serviettes',
          room: salleDeBain,
          difficulty: 1,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'DOWN', 'UP', 'DOWN', 'RIGHT'],
          isDefault: true,
        ),

        // --- SALON (4 tâches) ---
        Chore(
          id: 'salon_aspiration_tapis',
          name: 'Passer l\'aspirateur & tapis',
          room: salon,
          difficulty: 2,
          periodicityDays: 3,
          stratagemSequence: ['LEFT', 'LEFT', 'RIGHT', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_depoussierage',
          name: 'Dépoussiérer meubles & étagères',
          room: salon,
          difficulty: 2,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'RIGHT', 'UP', 'LEFT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_vitres',
          name: 'Laver les vitres & baies',
          room: salon,
          difficulty: 4,
          periodicityDays: 30,
          stratagemSequence: ['RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN', 'LEFT'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_canape',
          name: 'Nettoyer & aérer le canapé',
          room: salon,
          difficulty: 3,
          periodicityDays: 14,
          stratagemSequence: ['DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN', 'LEFT'],
          isDefault: true,
        ),

        // --- CHAMBRE (4 tâches) ---
        Chore(
          id: 'chambre_changer_draps',
          name: 'Changer draps & housses de couette',
          room: chambre,
          difficulty: 2,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'UP', 'DOWN', 'DOWN', 'LEFT', 'RIGHT'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_aspiration_sol',
          name: 'Aspiration & lavage du sol',
          room: chambre,
          difficulty: 2,
          periodicityDays: 4,
          stratagemSequence: ['DOWN', 'RIGHT', 'LEFT', 'UP', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_penderie',
          name: 'Rangement & tri de la penderie',
          room: chambre,
          difficulty: 3,
          periodicityDays: 14,
          stratagemSequence: ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_tables_chevet',
          name: 'Dépoussiérer tables de chevet & lampes',
          room: chambre,
          difficulty: 1,
          periodicityDays: 7,
          stratagemSequence: ['RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'],
          isDefault: true,
        ),
      ];

  /// Filters default chores for a specific room.
  static List<Chore> defaultChoresForRoom(String room) {
    return defaultChores.where((chore) => chore.room == room).toList();
  }
}
```

#### `app/lib/models.dart`
```dart
export 'models/chore.dart';
export 'models/mission_log.dart';
export 'models/user_profile.dart';
export 'models/room_category.dart';
```

---

## 5. Verification Method

Once Worker creates the files in `app/lib/models/` and updates `app/lib/models.dart`:

1. **Static Analysis**:
   ```powershell
   flutter analyze lib/models/ lib/models.dart
   ```
   *Expected outcome*: 0 issues found.

2. **Unit Test Verification**:
   Worker should copy `.agents/teamwork/explorer_m1_1/proposed_models_test.dart` to `app/test/unit/models_test.dart` and run:
   ```powershell
   flutter test test/unit/models_test.dart
   ```
   *Expected outcome*: 16 passing unit tests across all 5 test groups (`Chore Model`, `MissionLog Model`, `UserProfile Model`, `RoomCategory & Predefined Catalogue`, and `Backwards Compatibility with legacy models.dart`).

3. **Legacy Caller Verification**:
   ```powershell
   flutter analyze lib/targeting_engine.dart
   ```
   *Expected outcome*: `app/lib/targeting_engine.dart` compiles cleanly without any warnings or missing argument errors.

4. **Invalidation Conditions**:
   - If `Chore.room` or other fields are made `required` without defaults, `targeting_engine.dart` will fail compilation.
   - If `stratagemSequence` is cast as `map['stratagemSequence'] as List<String>`, runtime `TypeError` will occur when deserializing JSON or Firestore dynamic lists.
