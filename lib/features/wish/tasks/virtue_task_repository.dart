import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'virtue_task.dart';

/// Repository for reading and writing virtue tasks from/to Supabase.
/// Also handles fetching matched help requests for social tasks.
class VirtueTaskRepository {
  final SupabaseClient _supabase;

  VirtueTaskRepository(this._supabase);

  /// Fetch all virtue tasks for the current user.
  Future<List<VirtueTask>> getMyTasks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('wish_virtue_tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => VirtueTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch tasks for the current user filtered by virtue name.
  Future<List<VirtueTask>> getTasksForVirtue(String virtueName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('wish_virtue_tasks')
        .select()
        .eq('user_id', userId)
        .eq('virtue_name', virtueName)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => VirtueTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update task status (e.g. mark as in_progress or completed).
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final statusStr = status == TaskStatus.inProgress
        ? 'in_progress'
        : status == TaskStatus.completed
            ? 'completed'
            : 'pending';

    await _supabase
        .from('wish_virtue_tasks')
        .update({'status': statusStr, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', taskId);
  }

  /// Insert a new AI-generated virtue task for the user.
  Future<void> insertTask({
    required String virtueName,
    required TaskType taskType,
    required String title,
    required String description,
    required int xpReward,
    String? linkedRequestId,
    String? socialRole,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('wish_virtue_tasks').insert({
      'user_id': userId,
      'virtue_name': virtueName,
      'task_type': taskType == TaskType.social ? 'social' : 'individual',
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'status': 'pending',
      'linked_request_id': linkedRequestId,
      'social_role': socialRole,
    });
  }

  /// Find open help requests that match a given virtue and role.
  /// e.g. Courage + helper → mentoring requests
  Future<List<Map<String, dynamic>>> findMatchedRequests({
    required String virtue,
    required String role, // 'helper' or 'helpee'
  }) async {
    // Map virtue → relevant category keywords
    final categoryMap = {
      'Courage': ['social anxiety', 'confidence', 'public speaking', 'leadership'],
      'Wisdom': ['learning', 'education', 'mentoring', 'research'],
      'Compassion': ['mental health', 'grief', 'support', 'wellbeing'],
      'Discipline': ['fitness', 'habits', 'productivity', 'routine'],
      'Integrity': ['ethics', 'accountability', 'honesty', 'values'],
    };

    final keywords = categoryMap[virtue] ?? [];
    if (keywords.isEmpty) return [];

    // Search for open requests with matching tags or category
    final response = await _supabase
        .from('help_requests')
        .select('id, title, description, category, tags, allow_join_need')
        .eq('status', 'open')
        .limit(10);

    final all = response as List<dynamic>;

    // Filter client-side by keyword match in tags or category
    return all
        .cast<Map<String, dynamic>>()
        .where((req) {
          final tags = (req['tags'] as List<dynamic>?)?.join(' ').toLowerCase() ?? '';
          final cat = (req['category'] as String? ?? '').toLowerCase();
          final desc = (req['description'] as String? ?? '').toLowerCase();
          return keywords.any((kw) =>
              tags.contains(kw) || cat.contains(kw) || desc.contains(kw));
        })
        .toList();
  }
}

final virtueTaskRepositoryProvider = Provider<VirtueTaskRepository>((ref) {
  return VirtueTaskRepository(Supabase.instance.client);
});

final virtueTasksProvider = FutureProvider<List<VirtueTask>>((ref) async {
  final repo = ref.read(virtueTaskRepositoryProvider);
  return repo.getMyTasks();
});
