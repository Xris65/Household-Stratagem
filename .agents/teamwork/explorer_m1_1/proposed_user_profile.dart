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
