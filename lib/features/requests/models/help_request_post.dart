class HelpRequestPost {
  final String id;
  final String requestId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final String? userName;
  final String? userPhoto;

  HelpRequestPost({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.userName,
    this.userPhoto,
  });

  factory HelpRequestPost.fromJson(Map<String, dynamic> json) {
    return HelpRequestPost(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  HelpRequestPost copyWith({String? userName, String? userPhoto}) {
    return HelpRequestPost(
      id: id,
      requestId: requestId,
      userId: userId,
      message: message,
      createdAt: createdAt,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
    );
  }
}
