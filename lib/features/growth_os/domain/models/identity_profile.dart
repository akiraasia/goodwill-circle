class IdentityProfile {
  final String userId;
  final String? currentIdentity;
  final String? desiredIdentity;
  final String? personalityType;
  final List<String> valuesList;
  final String? learningStyle;
  final String? communicationStyle;
  final String? intrinsicMotivation;
  final String? extrinsicMotivation;
  final String? currentPhase;
  final String identityStage;
  final int weeklyTimeBudgetHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  IdentityProfile({
    required this.userId,
    this.currentIdentity,
    this.desiredIdentity,
    this.personalityType,
    this.valuesList = const [],
    this.learningStyle,
    this.communicationStyle,
    this.intrinsicMotivation,
    this.extrinsicMotivation,
    this.currentPhase,
    this.identityStage = 'Seed',
    this.weeklyTimeBudgetHours = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IdentityProfile.fromMap(Map<String, dynamic> map) {
    return IdentityProfile(
      userId: map['user_id'] ?? '',
      currentIdentity: map['current_identity'],
      desiredIdentity: map['desired_identity'],
      personalityType: map['personality_type'],
      valuesList: List<String>.from(map['values_list'] ?? []),
      learningStyle: map['learning_style'],
      communicationStyle: map['communication_style'],
      intrinsicMotivation: map['intrinsic_motivation'],
      extrinsicMotivation: map['extrinsic_motivation'],
      currentPhase: map['current_phase'],
      identityStage: map['identity_stage'] ?? 'Seed',
      weeklyTimeBudgetHours: map['weekly_time_budget_hours'] ?? 5,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'current_identity': currentIdentity,
      'desired_identity': desiredIdentity,
      'personality_type': personalityType,
      'values_list': valuesList,
      'learning_style': learningStyle,
      'communication_style': communicationStyle,
      'intrinsic_motivation': intrinsicMotivation,
      'extrinsic_motivation': extrinsicMotivation,
      'current_phase': currentPhase,
      'identity_stage': identityStage,
      'weekly_time_budget_hours': weeklyTimeBudgetHours,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  IdentityProfile copyWith({
    String? currentIdentity,
    String? desiredIdentity,
    String? personalityType,
    List<String>? valuesList,
    String? learningStyle,
    String? communicationStyle,
    String? intrinsicMotivation,
    String? extrinsicMotivation,
    String? currentPhase,
    String? identityStage,
    int? weeklyTimeBudgetHours,
  }) {
    return IdentityProfile(
      userId: userId,
      currentIdentity: currentIdentity ?? this.currentIdentity,
      desiredIdentity: desiredIdentity ?? this.desiredIdentity,
      personalityType: personalityType ?? this.personalityType,
      valuesList: valuesList ?? this.valuesList,
      learningStyle: learningStyle ?? this.learningStyle,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      intrinsicMotivation: intrinsicMotivation ?? this.intrinsicMotivation,
      extrinsicMotivation: extrinsicMotivation ?? this.extrinsicMotivation,
      currentPhase: currentPhase ?? this.currentPhase,
      identityStage: identityStage ?? this.identityStage,
      weeklyTimeBudgetHours: weeklyTimeBudgetHours ?? this.weeklyTimeBudgetHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
