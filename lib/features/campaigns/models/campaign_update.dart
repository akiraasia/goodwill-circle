class CampaignUpdate {
  final String id;
  final String campaignId;
  final String message;
  final DateTime createdAt;

  CampaignUpdate({
    required this.id,
    required this.campaignId,
    required this.message,
    required this.createdAt,
  });

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignUpdate(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
