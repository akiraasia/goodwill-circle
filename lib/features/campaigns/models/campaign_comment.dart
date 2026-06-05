class CampaignComment {
  final String id;
  final String campaignId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final String? userName;
  final String? userPhoto;

  CampaignComment({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.userName,
    this.userPhoto,
  });

  factory CampaignComment.fromJson(Map<String, dynamic> json) {
    return CampaignComment(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  CampaignComment copyWith({String? userName, String? userPhoto}) {
    return CampaignComment(
      id: id,
      campaignId: campaignId,
      userId: userId,
      message: message,
      createdAt: createdAt,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
    );
  }
}
