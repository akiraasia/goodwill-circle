class HelpRequest {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String category;
  final String status;
  final int goodwillReward;
  final int volunteersCount;
  final DateTime createdAt;

  // We might want to join the creator's name/photo
  final String? creatorName;
  final String? creatorPhoto;

  HelpRequest({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.goodwillReward,
    required this.volunteersCount,
    required this.createdAt,
    this.creatorName,
    this.creatorPhoto,
  });

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      goodwillReward: json['goodwill_reward'] as int? ?? 0,
      volunteersCount: json['volunteers_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      creatorName: json['profiles'] != null
          ? json['profiles']['name'] as String?
          : null,
      creatorPhoto: json['profiles'] != null
          ? json['profiles']['photo_url'] as String?
          : null,
    );
  }

  HelpRequest copyWith({String? creatorName, String? creatorPhoto}) {
    return HelpRequest(
      id: id,
      creatorId: creatorId,
      title: title,
      description: description,
      category: category,
      status: status,
      goodwillReward: goodwillReward,
      volunteersCount: volunteersCount,
      createdAt: createdAt,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'goodwill_reward': goodwillReward,
      'volunteers_count': volunteersCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
