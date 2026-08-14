import 'package:goodwill_circle/features/requests/models/help_request.dart';

class WishModuleTaskDraft {
  final String title;
  final String description;
  final String virtue;
  final String difficulty;
  final int rewardPoints;
  final int durationMinutes;
  final String? linkedRequestId;

  const WishModuleTaskDraft({
    required this.title,
    required this.description,
    required this.virtue,
    required this.difficulty,
    required this.rewardPoints,
    required this.durationMinutes,
    this.linkedRequestId,
  });

  bool get isHelpRequest => linkedRequestId != null;
}

class WishModuleTask {
  final String id;
  final String wishId;
  final String title;
  final String description;
  final String virtue;
  final String difficulty;
  final int rewardPoints;
  final int durationMinutes;
  final String? linkedRequestId;
  final String status;
  final DateTime createdAt;

  const WishModuleTask({
    required this.id,
    required this.wishId,
    required this.title,
    required this.description,
    required this.virtue,
    required this.difficulty,
    required this.rewardPoints,
    required this.durationMinutes,
    required this.linkedRequestId,
    required this.status,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isHelpRequest => linkedRequestId != null;

  factory WishModuleTask.fromJson(Map<String, dynamic> json) {
    return WishModuleTask(
      id: json['id']?.toString() ?? '',
      wishId: json['wish_id']?.toString() ?? '',
      title: json['task_text'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      virtue: json['virtue'] as String? ?? 'Courage',
      difficulty: _difficulty(json['difficulty'] as String?),
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 10,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 5,
      linkedRequestId: json['linked_request_id'] as String?,
      status: json['status'] as String? ?? 'assigned',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  WishModuleTask copyWith({String? status}) {
    return WishModuleTask(
      id: id,
      wishId: wishId,
      title: title,
      description: description,
      virtue: virtue,
      difficulty: difficulty,
      rewardPoints: rewardPoints,
      durationMinutes: durationMinutes,
      linkedRequestId: linkedRequestId,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  static String _difficulty(String? value) {
    return value?.toLowerCase() == 'hard' ? 'hard' : 'easy';
  }
}

class WishModuleDiaryEntry {
  final String dateKey;
  final int moodIndex;
  final String moodLabel;
  final String reflection;
  final String gratitude;
  final String thoughtOfDay;
  final String sentiment;

  const WishModuleDiaryEntry({
    required this.dateKey,
    required this.moodIndex,
    required this.moodLabel,
    required this.reflection,
    required this.gratitude,
    required this.thoughtOfDay,
    required this.sentiment,
  });

  factory WishModuleDiaryEntry.fromJson(Map<String, dynamic> json) {
    return WishModuleDiaryEntry(
      dateKey: json['entry_date'] as String? ?? '',
      moodIndex: (json['mood_index'] as num?)?.toInt() ?? 0,
      moodLabel: json['mood_label'] as String? ?? 'Hopeful',
      reflection: json['reflection'] as String? ?? '',
      gratitude: json['gratitude'] as String? ?? '',
      thoughtOfDay: json['thought_of_day'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
    );
  }
}

class WishAgentInsight {
  final String sentiment;
  final String primaryVirtue;
  final String suggestedReplyStyle;
  final List<WishModuleTaskDraft> tasks;

  const WishAgentInsight({
    required this.sentiment,
    required this.primaryVirtue,
    required this.suggestedReplyStyle,
    required this.tasks,
  });
}

class WishAgentInsightData {
  final String sentiment;
  final String primaryVirtue;

  const WishAgentInsightData({
    required this.sentiment,
    required this.primaryVirtue,
  });
}

extension HelpRequestWishSummary on HelpRequest {
  Map<String, dynamic> get wishAgentSummary => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'tags': tags,
        'difficulty': difficulty,
        'goodwill_reward': goodwillReward,
        'community_request': isCommunityRequest,
      };
}
