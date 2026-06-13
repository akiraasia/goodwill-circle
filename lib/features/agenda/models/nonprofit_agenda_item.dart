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
  final int helperCount;
  final int helpieCount;
  final int supportCount;
  final bool hasSupported;
  final DateTime createdAt;
  final String? myParticipantStatus;
  final int completedConnectionsCount;

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
    this.helperCount = 0,
    this.helpieCount = 0,
    this.supportCount = 0,
    this.hasSupported = false,
    required this.createdAt,
    this.myParticipantStatus,
    this.completedConnectionsCount = 0,
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
      helperCount: json['helper_count'] as int? ?? 0,
      helpieCount: json['helpie_count'] as int? ?? 0,
      supportCount: json['support_count'] as int? ?? 0,
      hasSupported: json['has_supported'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedConnectionsCount: json['completed_connections_count'] as int? ?? 0,
    );
  }

  NonprofitAgendaItem copyWith({
    String? ngoVerificationStatus,
    String? myParticipantStatus,
    int? completedConnectionsCount,
    int? helperCount,
    int? helpieCount,
    int? supportCount,
    bool? hasSupported,
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
      helperCount: helperCount ?? this.helperCount,
      helpieCount: helpieCount ?? this.helpieCount,
      supportCount: supportCount ?? this.supportCount,
      hasSupported: hasSupported ?? this.hasSupported,
      createdAt: createdAt,
      myParticipantStatus: myParticipantStatus ?? this.myParticipantStatus,
      completedConnectionsCount:
          completedConnectionsCount ?? this.completedConnectionsCount,
    );
  }
}
