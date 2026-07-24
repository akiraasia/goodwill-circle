import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for storing user's wish history and story progression
class WishHistory {
  final String id;
  final String userId;
  final String initialWish;
  final Map<String, dynamic> interviewData;
  final List<String> assignedVirtues;
  final Map<String, int> assignedStats;
  final String pathMode; // 'story' or 'task'
  final Map<String, dynamic> storyProgress;
  final String completionStatus;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const WishHistory({
    required this.id,
    required this.userId,
    required this.initialWish,
    required this.interviewData,
    required this.assignedVirtues,
    required this.assignedStats,
    required this.pathMode,
    required this.storyProgress,
    required this.completionStatus,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory WishHistory.fromJson(Map<String, dynamic> json) {
    return WishHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      initialWish: json['initial_wish'] as String,
      interviewData: json['interview_data'] as Map<String, dynamic>? ?? {},
      assignedVirtues: List<String>.from(json['assigned_virtues'] as List? ?? []),
      assignedStats: Map<String, int>.from(json['assigned_stats'] as Map? ?? {'physical': 1, 'mental': 1, 'ethical': 1}),
      pathMode: json['path_mode'] as String? ?? 'task',
      storyProgress: json['story_progress'] as Map<String, dynamic>? ?? {},
      completionStatus: json['completion_status'] as String? ?? 'started',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'initial_wish': initialWish,
    'interview_data': interviewData,
    'assigned_virtues': assignedVirtues,
    'assigned_stats': assignedStats,
    'path_mode': pathMode,
    'story_progress': storyProgress,
    'completion_status': completionStatus,
  };
}

/// Repository for managing wish history and persistence
class WishHistoryRepository {
  final SupabaseClient _supabase;

  WishHistoryRepository(this._supabase);

  /// Get or create the current user's wish history
  Future<WishHistory?> getCurrentWish() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('wish_history')
          .select()
          .eq('user_id', userId)
          .single();

      return WishHistory.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // No wish history found
      return null;
    }
  }

  /// Create a new wish history entry
  Future<WishHistory> createWish({
    required String initialWish,
    Map<String, dynamic>? interviewData,
    List<String>? assignedVirtues,
    Map<String, int>? assignedStats,
    String pathMode = 'task',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // First, delete any existing wish for this user (upsert)
      await _supabase
          .from('wish_history')
          .delete()
          .eq('user_id', userId);
    } catch (_) {
      // Ignore if no existing record
    }

    final data = {
      'user_id': userId,
      'initial_wish': initialWish,
      'interview_data': interviewData ?? {},
      'assigned_virtues': assignedVirtues ?? [],
      'assigned_stats': assignedStats ?? {'physical': 1, 'mental': 1, 'ethical': 1},
      'path_mode': pathMode,
      'completion_status': 'started',
    };

    final response = await _supabase
        .from('wish_history')
        .insert(data)
        .select()
        .single();

    return WishHistory.fromJson(response as Map<String, dynamic>);
  }

  /// Update existing wish history with new data
  Future<WishHistory> updateWish({
    required String wishHistoryId,
    Map<String, dynamic>? interviewData,
    List<String>? assignedVirtues,
    Map<String, int>? assignedStats,
    String? pathMode,
    Map<String, dynamic>? storyProgress,
    String? completionStatus,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (interviewData != null) updates['interview_data'] = interviewData;
    if (assignedVirtues != null) updates['assigned_virtues'] = assignedVirtues;
    if (assignedStats != null) updates['assigned_stats'] = assignedStats;
    if (pathMode != null) updates['path_mode'] = pathMode;
    if (storyProgress != null) updates['story_progress'] = storyProgress;
    if (completionStatus != null) updates['completion_status'] = completionStatus;
    updates['last_updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('wish_history')
        .update(updates)
        .eq('id', wishHistoryId)
        .eq('user_id', userId)
        .select()
        .single();

    return WishHistory.fromJson(response as Map<String, dynamic>);
  }

  /// Delete wish history (user starts over)
  Future<void> deleteWish(String wishHistoryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('wish_history')
        .delete()
        .eq('id', wishHistoryId)
        .eq('user_id', userId);
  }
}

/// Provider for wish history repository
final wishHistoryRepositoryProvider = Provider<WishHistoryRepository>((ref) {
  return WishHistoryRepository(Supabase.instance.client);
});

/// Provider for current user's wish history
final currentWishProvider = FutureProvider<WishHistory?>((ref) async {
  final repo = ref.read(wishHistoryRepositoryProvider);
  return repo.getCurrentWish();
});
