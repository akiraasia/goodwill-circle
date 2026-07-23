class GrowthEvent {
  final String id;
  final String userId;
  final String eventType;
  final String evidence;
  final String? impactArea;
  final int? durationMinutes;
  final bool verified;
  final String? missionId;
  final DateTime createdAt;

  GrowthEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.evidence,
    this.impactArea,
    this.durationMinutes,
    this.verified = false,
    this.missionId,
    required this.createdAt,
  });

  factory GrowthEvent.fromMap(Map<String, dynamic> map) {
    return GrowthEvent(
      id: map['id'],
      userId: map['user_id'],
      eventType: map['event_type'],
      evidence: map['evidence'],
      impactArea: map['impact_area'],
      durationMinutes: map['duration_minutes'],
      verified: map['verified'] ?? false,
      missionId: map['mission_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'event_type': eventType,
      'evidence': evidence,
      'impact_area': impactArea,
      'duration_minutes': durationMinutes,
      'verified': verified,
      'mission_id': missionId,
    };
  }
}
