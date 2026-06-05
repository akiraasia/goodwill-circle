class CampaignDonation {
  final String id;
  final String campaignId;
  final String donorId;
  final int amount;
  final DateTime createdAt;

  final String? donorName;
  final String? donorPhoto;

  CampaignDonation({
    required this.id,
    required this.campaignId,
    required this.donorId,
    required this.amount,
    required this.createdAt,
    this.donorName,
    this.donorPhoto,
  });

  factory CampaignDonation.fromJson(Map<String, dynamic> json) {
    return CampaignDonation(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      donorId: json['donor_id'] as String,
      amount: json['amount'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      donorName: json['profiles'] != null
          ? json['profiles']['name'] as String?
          : null,
      donorPhoto: json['profiles'] != null
          ? json['profiles']['photo_url'] as String?
          : null,
    );
  }

  CampaignDonation copyWith({String? donorName, String? donorPhoto}) {
    return CampaignDonation(
      id: id,
      campaignId: campaignId,
      donorId: donorId,
      amount: amount,
      createdAt: createdAt,
      donorName: donorName ?? this.donorName,
      donorPhoto: donorPhoto ?? this.donorPhoto,
    );
  }
}
