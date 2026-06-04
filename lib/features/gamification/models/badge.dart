class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
    );
  }
}

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime awardedAt;

  // Joined relation
  final Badge? badgeDetails;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.awardedAt,
    this.badgeDetails,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      awardedAt: DateTime.parse(json['awarded_at'] as String),
      badgeDetails: json['badges'] != null
          ? Badge.fromJson(json['badges'])
          : null,
    );
  }
}
