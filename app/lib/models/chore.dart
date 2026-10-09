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
  final int durationMinutes;
  final DateTime? lastCompletedAt;
  final List<String> stratagemSequence;
  final bool isDefault;
  final bool enabled;

  List<String> get swipeSequence => stratagemSequence;

  Chore({
    required this.id,
    required this.name,
    this.room = 'Cuisine',
    required this.difficulty,
    this.periodicityDays = 7,
    this.durationMinutes = 10,
    this.lastCompletedAt,
    List<String>? stratagemSequence,
    List<String>? swipeSequence,
    this.isDefault = false,
    this.enabled = true,
  }) : stratagemSequence =
            stratagemSequence ?? swipeSequence ?? const [];

  /// Factory constructor to deserialize from a Map (e.g. from Firestore or JSON).
  factory Chore.fromMap(Map<String, dynamic> map, [String? id]) {
    final seq = (map['stratagemSequence'] ?? map['swipeSequence']) as List?;
    return Chore(
      id: id ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      room: map['room']?.toString() ?? 'Cuisine',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      periodicityDays: (map['periodicityDays'] as num?)?.toInt() ?? 7,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 10,
      lastCompletedAt: _parseDateTime(map['lastCompletedAt']),
      stratagemSequence: seq?.map((e) => e.toString()).toList() ?? const [],
      isDefault: map['isDefault'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? true,
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
      'durationMinutes': durationMinutes,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'stratagemSequence': List<String>.from(stratagemSequence),
      'swipeSequence': List<String>.from(stratagemSequence),
      'isDefault': isDefault,
      'enabled': enabled,
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
    int? durationMinutes,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    List<String>? stratagemSequence,
    List<String>? swipeSequence,
    bool? isDefault,
    bool? enabled,
  }) {
    return Chore(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      difficulty: difficulty ?? this.difficulty,
      periodicityDays: periodicityDays ?? this.periodicityDays,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lastCompletedAt: clearLastCompletedAt
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      stratagemSequence:
          stratagemSequence ?? swipeSequence ?? this.stratagemSequence,
      isDefault: isDefault ?? this.isDefault,
      enabled: enabled ?? this.enabled,
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
          durationMinutes == other.durationMinutes &&
          lastCompletedAt == other.lastCompletedAt &&
          _listEquals(stratagemSequence, other.stratagemSequence) &&
          isDefault == other.isDefault &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        room,
        difficulty,
        periodicityDays,
        durationMinutes,
        lastCompletedAt,
        Object.hashAll(stratagemSequence),
        isDefault,
        enabled,
      );

  @override
  String toString() {
    return 'Chore(id: $id, name: "$name", room: "$room", difficulty: $difficulty, '
        'periodicityDays: $periodicityDays, durationMinutes: $durationMinutes, lastCompletedAt: $lastCompletedAt, '
        'stratagemSequence: $stratagemSequence, isDefault: $isDefault, enabled: $enabled)';
  }
}

