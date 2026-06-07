class Campaign {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final int goalAmount;
  final int currentAmount;
  final int supportersCount;
  final int membersCount;
  final int votesCount;
  final bool isJoined;
  final bool isVoted;
  final bool isVerified;
  final String? imageUrl;
  final String status;
  final String verificationStatus;
  final DateTime? endDate;
  final DateTime createdAt;

  final String? creatorName;
  final String? creatorPhoto;
  final String? creatorVerificationStatus;

  Campaign({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currentAmount,
    required this.supportersCount,
    this.membersCount = 0,
    this.votesCount = 0,
    this.isJoined = false,
    this.isVoted = false,
    this.isVerified = false,
    this.imageUrl,
    required this.status,
    this.verificationStatus = 'unverified',
    this.endDate,
    required this.createdAt,
    this.creatorName,
    this.creatorPhoto,
    this.creatorVerificationStatus,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      goalAmount: json['goal_amount'] as int? ?? 0,
      currentAmount: json['current_amount'] as int? ?? 0,
      supportersCount: json['supporters_count'] as int? ?? 0,
      membersCount: json['members_count'] as int? ?? 0,
      votesCount: json['votes_count'] as int? ?? 0,
      isVerified: json['verification_status'] == 'verified',
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'active',
      verificationStatus:
          json['verification_status'] as String? ?? 'unverified',
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      creatorName: json['profiles'] != null
          ? json['profiles']['name'] as String?
          : null,
      creatorPhoto: json['profiles'] != null
          ? json['profiles']['photo_url'] as String?
          : null,
      creatorVerificationStatus: json['profiles'] != null
          ? json['profiles']['verification_status'] as String?
          : null,
    );
  }

  Campaign copyWith({
    String? creatorName,
    String? creatorPhoto,
    String? imageUrl,
    int? membersCount,
    int? votesCount,
    bool? isJoined,
    bool? isVoted,
    bool? isVerified,
    String? verificationStatus,
    String? creatorVerificationStatus,
  }) {
    return Campaign(
      id: id,
      creatorId: creatorId,
      title: title,
      description: description,
      goalAmount: goalAmount,
      currentAmount: currentAmount,
      supportersCount: supportersCount,
      membersCount: membersCount ?? this.membersCount,
      votesCount: votesCount ?? this.votesCount,
      isJoined: isJoined ?? this.isJoined,
      isVoted: isVoted ?? this.isVoted,
      isVerified: isVerified ?? this.isVerified,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      endDate: endDate,
      createdAt: createdAt,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
      creatorVerificationStatus:
          creatorVerificationStatus ?? this.creatorVerificationStatus,
    );
  }

  double get progressPercentage {
    if (goalAmount <= 0) return 0;
    final progress = currentAmount / goalAmount;
    return progress > 1.0 ? 1.0 : progress;
  }
}
