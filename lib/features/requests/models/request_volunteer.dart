class RequestVolunteer {
  final String id;
  final String requestId;
  final String volunteerId;
  final String status;
  final DateTime createdAt;

  RequestVolunteer({
    required this.id,
    required this.requestId,
    required this.volunteerId,
    required this.status,
    required this.createdAt,
  });

  factory RequestVolunteer.fromJson(Map<String, dynamic> json) {
    return RequestVolunteer(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      volunteerId: json['volunteer_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'volunteer_id': volunteerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
