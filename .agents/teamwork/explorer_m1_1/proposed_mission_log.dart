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
