class NonprofitAgendaItem {
  final String id;
  final String ngoId;
  final String ngoName;
  final String ngoVerificationStatus;
  final String title;
  final String description;
  final String skillArea;
  final String location;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int seatsNeeded;
  final int seatsFilled;
  final String rewardBadgeId;
  final String certificateTitle;
  final String certificateIssuer;
  final String status;
  final DateTime createdAt;
  final String? myParticipantStatus;

  NonprofitAgendaItem({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    this.ngoVerificationStatus = 'unverified',
    required this.title,
    required this.description,
    required this.skillArea,
    required this.location,
    this.startsAt,
    this.endsAt,
    required this.seatsNeeded,
    required this.seatsFilled,
    required this.rewardBadgeId,
    required this.certificateTitle,
    required this.certificateIssuer,
    required this.status,
    required this.createdAt,
    this.myParticipantStatus,
  });

  factory NonprofitAgendaItem.fromJson(Map<String, dynamic> json) {
    return NonprofitAgendaItem(
      id: json['id'] as String,
      ngoId: json['ngo_id'] as String,
      ngoName: json['ngo_name'] as String? ?? 'Nonprofit partner',
      ngoVerificationStatus:
          json['ngo_verification_status'] as String? ?? 'unverified',
      title: json['title'] as String,
      description: json['description'] as String,
      skillArea: json['skill_area'] as String,
      location: json['location'] as String,
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
      seatsNeeded: json['seats_needed'] as int? ?? 1,
      seatsFilled: json['seats_filled'] as int? ?? 0,
      rewardBadgeId: json['reward_badge_id'] as String? ?? 'mentor',
      certificateTitle:
          json['certificate_title'] as String? ?? 'Community Mentor',
      certificateIssuer:
          json['certificate_issuer'] as String? ?? 'Goodwill Circle NGO',
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NonprofitAgendaItem copyWith({
    String? ngoVerificationStatus,
    String? myParticipantStatus,
  }) {
    return NonprofitAgendaItem(
      id: id,
      ngoId: ngoId,
      ngoName: ngoName,
      ngoVerificationStatus:
          ngoVerificationStatus ?? this.ngoVerificationStatus,
      title: title,
      description: description,
      skillArea: skillArea,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      seatsNeeded: seatsNeeded,
      seatsFilled: seatsFilled,
      rewardBadgeId: rewardBadgeId,
      certificateTitle: certificateTitle,
      certificateIssuer: certificateIssuer,
      status: status,
      createdAt: createdAt,
      myParticipantStatus: myParticipantStatus ?? this.myParticipantStatus,
    );
  }
}
