class Campaign {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final int goalAmount;
  final int currentAmount;
  final int supportersCount;
  final String status;
  final DateTime? endDate;
  final DateTime createdAt;

  final String? creatorName;
  final String? creatorPhoto;

  Campaign({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currentAmount,
    required this.supportersCount,
    required this.status,
    this.endDate,
    required this.createdAt,
    this.creatorName,
    this.creatorPhoto,
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
      status: json['status'] as String? ?? 'active',
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
    );
  }

  double get progressPercentage {
    if (goalAmount <= 0) return 0;
    final progress = currentAmount / goalAmount;
    return progress > 1.0 ? 1.0 : progress;
  }
}
