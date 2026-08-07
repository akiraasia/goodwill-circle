import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      id: json['id'] as String? ?? 'cached_wish',
      userId: json['user_id'] as String? ?? 'local_user',
      initialWish: json['initial_wish'] as String? ?? '',
      interviewData: json['interview_data'] is Map<String, dynamic>
          ? json['interview_data'] as Map<String, dynamic>
          : {},
      assignedVirtues: List<String>.from(json['assigned_virtues'] as List? ?? []),
      assignedStats: Map<String, int>.from(
        json['assigned_stats'] as Map? ?? {'physical': 5, 'mental': 5, 'ethical': 5},
      ),
      pathMode: json['path_mode'] as String? ?? 'task',
      storyProgress: json['story_progress'] is Map<String, dynamic>
          ? json['story_progress'] as Map<String, dynamic>
          : {},
      completionStatus: json['completion_status'] as String? ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'initial_wish': initialWish,
    'interview_data': interviewData,
    'assigned_virtues': assignedVirtues,
    'assigned_stats': assignedStats,
    'path_mode': pathMode,
    'story_progress': storyProgress,
    'completion_status': completionStatus,
    'created_at': createdAt.toIso8601String(),
    'last_updated_at': lastUpdatedAt.toIso8601String(),
  };
}

/// Repository for managing wish history and persistence
class WishHistoryRepository {
  final SupabaseClient _supabase;

  WishHistoryRepository(this._supabase);

  /// Get or create the current user's wish history
  Future<WishHistory?> getCurrentWish() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      final cached = prefs.getString('cached_wish_history');
      if (cached != null) {
        try {
          return WishHistory.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
      return null;
    }

    try {
      final response = await _supabase
          .from('wish_history')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final wish = WishHistory.fromJson(response);
        await prefs.setString('cached_wish_history', jsonEncode(wish.toJson()));
        return wish;
      }
    } catch (e) {
      // Fall back to SharedPreferences on network or database error
    }

    final cached = prefs.getString('cached_wish_history');
    if (cached != null) {
      try {
        return WishHistory.fromJson(jsonDecode(cached));
      } catch (_) {}
    }

    return null;
  }

  /// Create a new wish history entry
  Future<WishHistory> createWish({
    required String initialWish,
    Map<String, dynamic>? interviewData,
    List<String>? assignedVirtues,
    Map<String, int>? assignedStats,
    String pathMode = 'task',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_wish', true);

    final userId = _supabase.auth.currentUser?.id;
    final nowStr = DateTime.now().toIso8601String();

    final localData = {
      'id': 'wish_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId ?? 'local_user',
      'initial_wish': initialWish,
      'interview_data': interviewData ?? {},
      'assigned_virtues': assignedVirtues ?? ['Courage'],
      'assigned_stats': assignedStats ?? {'physical': 5, 'mental': 5, 'ethical': 5},
      'path_mode': pathMode,
      'story_progress': {},
      'completion_status': 'completed',
      'created_at': nowStr,
      'last_updated_at': nowStr,
    };

    await prefs.setString('cached_wish_history', jsonEncode(localData));

    if (userId != null) {
      try {
        await _supabase
            .from('wish_history')
            .delete()
            .eq('user_id', userId);
      } catch (_) {}

      try {
        final response = await _supabase
            .from('wish_history')
            .insert({
              'user_id': userId,
              'initial_wish': initialWish,
              'interview_data': interviewData ?? {},
              'assigned_virtues': assignedVirtues ?? [],
              'assigned_stats': assignedStats ?? {'physical': 5, 'mental': 5, 'ethical': 5},
              'path_mode': pathMode,
              'completion_status': 'completed',
            })
            .select()
            .single();

        final wish = WishHistory.fromJson(response);
        await prefs.setString('cached_wish_history', jsonEncode(wish.toJson()));
        return wish;
      } catch (e) {
        // Continue with local cached version if remote insert fails
      }
    }

    return WishHistory.fromJson(localData);
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

    return WishHistory.fromJson(response);
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
