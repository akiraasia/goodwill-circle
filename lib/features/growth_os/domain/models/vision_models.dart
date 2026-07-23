class LifeVision {
  final String id;
  final String userId;
  final String visionStatement;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  LifeVision({
    required this.id,
    required this.userId,
    required this.visionStatement,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory LifeVision.fromMap(Map<String, dynamic> map) {
    return LifeVision(
      id: map['id'],
      userId: map['user_id'],
      visionStatement: map['vision_statement'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vision_statement': visionStatement,
      'status': status,
    };
  }
}

class Wish {
  final String id;
  final String userId;
  final String visionId;
  final String wishStatement;
  final String? category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wish({
    required this.id,
    required this.userId,
    required this.visionId,
    required this.wishStatement,
    this.category,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wish.fromMap(Map<String, dynamic> map) {
    return Wish(
      id: map['id'],
      userId: map['user_id'],
      visionId: map['vision_id'],
      wishStatement: map['wish_statement'],
      category: map['category'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vision_id': visionId,
      'wish_statement': wishStatement,
      'category': category,
      'status': status,
    };
  }
}

class Goal {
  final String id;
  final String userId;
  final String wishId;
  final String goalStatement;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.wishId,
    required this.goalStatement,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      userId: map['user_id'],
      wishId: map['wish_id'],
      goalStatement: map['goal_statement'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class Mission {
  final String id;
  final String userId;
  final String? milestoneId;
  final String missionStatement;
  final String? difficulty;
  final int? estimatedDurationMinutes;
  final String status;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Mission({
    required this.id,
    required this.userId,
    this.milestoneId,
    required this.missionStatement,
    this.difficulty,
    this.estimatedDurationMinutes,
    this.status = 'pending',
    this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'],
      userId: map['user_id'],
      milestoneId: map['milestone_id'],
      missionStatement: map['mission_statement'],
      difficulty: map['difficulty'],
      estimatedDurationMinutes: map['estimated_duration_minutes'],
      status: map['status'] ?? 'pending',
      scheduledFor: map['scheduled_for'] != null ? DateTime.parse(map['scheduled_for']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
