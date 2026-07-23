/// Represents a virtue task generated for the user based on their wish.
/// Tasks can be either individual (solo habit) or social (connects to a help request).
class VirtueTask {
  final String id;
  final String virtueName; // e.g. 'Courage', 'Wisdom', 'Compassion'
  final TaskType taskType;
  final String title;
  final String description;
  final int xpReward;
  final TaskStatus status;
  final String? linkedRequestId; // null for individual tasks
  final String? socialRole; // 'helper' or 'helpee'

  const VirtueTask({
    required this.id,
    required this.virtueName,
    required this.taskType,
    required this.title,
    required this.description,
    required this.xpReward,
    this.status = TaskStatus.pending,
    this.linkedRequestId,
    this.socialRole,
  });

  bool get isSocial => taskType == TaskType.social;
  bool get isIndividual => taskType == TaskType.individual;

  factory VirtueTask.fromJson(Map<String, dynamic> json) {
    return VirtueTask(
      id: json['id'] as String,
      virtueName: json['virtue_name'] as String,
      taskType: json['task_type'] == 'social' ? TaskType.social : TaskType.individual,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xp_reward'] as int? ?? 20,
      status: _parseStatus(json['status'] as String?),
      linkedRequestId: json['linked_request_id'] as String?,
      socialRole: json['social_role'] as String?,
    );
  }

  static TaskStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'in_progress': return TaskStatus.inProgress;
      case 'completed': return TaskStatus.completed;
      default: return TaskStatus.pending;
    }
  }
}

enum TaskType { social, individual }

enum TaskStatus { pending, inProgress, completed }
