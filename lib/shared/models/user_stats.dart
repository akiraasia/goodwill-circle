class UserStats {
  final String userId;
  final int credits;
  final int trustScore;
  final int impactScore;
  final int helpCount;
  final int campaignCount;
  final int freeRequests;
  final int creditsEarned;
  final int creditsDonated;
  final int campaignsSupported;
  final int reputationScore;
  final DateTime updatedAt;

  UserStats({
    required this.userId,
    required this.credits,
    required this.trustScore,
    required this.impactScore,
    required this.helpCount,
    required this.campaignCount,
    required this.freeRequests,
    required this.creditsEarned,
    required this.creditsDonated,
    required this.campaignsSupported,
    required this.reputationScore,
    required this.updatedAt,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      credits: json['credits'] as int? ?? 0,
      trustScore: json['trust_score'] as int? ?? 0,
      impactScore: json['impact_score'] as int? ?? 0,
      helpCount: json['help_count'] as int? ?? 0,
      campaignCount: json['campaign_count'] as int? ?? 0,
      freeRequests: json['free_requests'] as int? ?? 0,
      creditsEarned: json['credits_earned'] as int? ?? 0,
      creditsDonated: json['credits_donated'] as int? ?? 0,
      campaignsSupported: json['campaigns_supported'] as int? ?? 0,
      reputationScore: json['reputation_score'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'credits': credits,
      'trust_score': trustScore,
      'impact_score': impactScore,
      'help_count': helpCount,
      'campaign_count': campaignCount,
      'free_requests': freeRequests,
      'credits_earned': creditsEarned,
      'credits_donated': creditsDonated,
      'campaigns_supported': campaignsSupported,
      'reputation_score': reputationScore,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
