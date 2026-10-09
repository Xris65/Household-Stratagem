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
  final String agentName;
  final int level;
  final int credits;
  final int medals;
  final bool onboarded;
  final String? email;
  final String selectedAudioTrack;
  final DateTime createdAt;

  bool get isOnboarded => onboarded;
  String get preferredAudioTrack => selectedAudioTrack;

  UserProfile({
    required this.userId,
    this.agentName = 'Nettoyeur-1',
    this.level = 1,
    this.credits = 0,
    this.medals = 0,
    bool? onboarded,
    bool? isOnboarded,
    this.email,
    String? selectedAudioTrack,
    String? preferredAudioTrack,
    DateTime? createdAt,
  })  : onboarded = onboarded ?? isOnboarded ?? false,
        selectedAudioTrack = selectedAudioTrack ??
            preferredAudioTrack ??
            'tactical_ambiance_1.mp3',
        createdAt = createdAt ?? DateTime.now();

  /// Factory constructor to deserialize from a Map (e.g. from Firestore or JSON).
  factory UserProfile.fromMap(Map<String, dynamic> map, [String? userId]) {
    return UserProfile(
      userId: userId ?? map['userId']?.toString() ?? '',
      agentName: map['agentName']?.toString() ?? 'Nettoyeur-1',
      level: (map['level'] as num?)?.toInt() ?? 1,
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      medals: (map['medals'] as num?)?.toInt() ?? 0,
      onboarded: (map['onboarded'] as bool?) ??
          (map['isOnboarded'] as bool?) ??
          false,
      email: map['email']?.toString(),
      selectedAudioTrack: (map['selectedAudioTrack'] ??
              map['preferredAudioTrack'])
          ?.toString() ??
          'tactical_ambiance_1.mp3',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Serializes the profile to a Map suitable for Firestore or JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentName': agentName,
      'level': level,
      'credits': credits,
      'medals': medals,
      'onboarded': onboarded,
      'isOnboarded': onboarded,
      'email': email,
      'selectedAudioTrack': selectedAudioTrack,
      'preferredAudioTrack': selectedAudioTrack,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this user profile with modified fields.
  UserProfile copyWith({
    String? userId,
    String? agentName,
    int? level,
    int? credits,
    int? medals,
    bool? onboarded,
    bool? isOnboarded,
    String? email,
    String? selectedAudioTrack,
    String? preferredAudioTrack,
    DateTime? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      agentName: agentName ?? this.agentName,
      level: level ?? this.level,
      credits: credits ?? this.credits,
      medals: medals ?? this.medals,
      onboarded: onboarded ?? isOnboarded ?? this.onboarded,
      email: email ?? this.email,
      selectedAudioTrack: selectedAudioTrack ??
          preferredAudioTrack ??
          this.selectedAudioTrack,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          agentName == other.agentName &&
          level == other.level &&
          credits == other.credits &&
          medals == other.medals &&
          onboarded == other.onboarded &&
          email == other.email &&
          selectedAudioTrack == other.selectedAudioTrack &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        userId,
        agentName,
        level,
        credits,
        medals,
        onboarded,
        email,
        selectedAudioTrack,
        createdAt,
      );

  @override
  String toString() {
    return 'UserProfile(userId: "$userId", agentName: "$agentName", level: $level, '
        'credits: $credits, medals: $medals, onboarded: $onboarded, email: "$email", '
        'selectedAudioTrack: "$selectedAudioTrack", createdAt: $createdAt)';
  }
}
