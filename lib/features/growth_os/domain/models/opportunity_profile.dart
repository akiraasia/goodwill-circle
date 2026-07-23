class OpportunityProfile {
  final String userId;
  final List<String> canTeach;
  final List<String> canLearn;
  final String? preferredTeachingStyle;
  final String? preferredLearningStyle;
  final int communityTrustScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  OpportunityProfile({
    required this.userId,
    this.canTeach = const [],
    this.canLearn = const [],
    this.preferredTeachingStyle,
    this.preferredLearningStyle,
    this.communityTrustScore = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpportunityProfile.fromMap(Map<String, dynamic> map) {
    return OpportunityProfile(
      userId: map['user_id'] ?? '',
      canTeach: List<String>.from(map['can_teach'] ?? []),
      canLearn: List<String>.from(map['can_learn'] ?? []),
      preferredTeachingStyle: map['preferred_teaching_style'],
      preferredLearningStyle: map['preferred_learning_style'],
      communityTrustScore: map['community_trust_score'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'can_teach': canTeach,
      'can_learn': canLearn,
      'preferred_teaching_style': preferredTeachingStyle,
      'preferred_learning_style': preferredLearningStyle,
      'community_trust_score': communityTrustScore,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  OpportunityProfile copyWith({
    List<String>? canTeach,
    List<String>? canLearn,
    String? preferredTeachingStyle,
    String? preferredLearningStyle,
    int? communityTrustScore,
  }) {
    return OpportunityProfile(
      userId: userId,
      canTeach: canTeach ?? this.canTeach,
      canLearn: canLearn ?? this.canLearn,
      preferredTeachingStyle: preferredTeachingStyle ?? this.preferredTeachingStyle,
      preferredLearningStyle: preferredLearningStyle ?? this.preferredLearningStyle,
      communityTrustScore: communityTrustScore ?? this.communityTrustScore,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
