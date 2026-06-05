import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/gamification/models/badge.dart';
import 'package:goodwill_circle/features/gamification/models/goodwill_chain_summary.dart';

class GamificationState {
  final List<UserBadge> badges;
  final GoodwillChainSummary? chainSummary;
  final bool isLoading;
  final String? error;

  GamificationState({
    this.badges = const [],
    this.chainSummary,
    this.isLoading = false,
    this.error,
  });

  GamificationState copyWith({
    List<UserBadge>? badges,
    GoodwillChainSummary? chainSummary,
    bool? isLoading,
    String? error,
  }) {
    return GamificationState(
      badges: badges ?? this.badges,
      chainSummary: chainSummary ?? this.chainSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final gamificationControllerProvider =
    NotifierProvider<GamificationController, GamificationState>(
      GamificationController.new,
    );

class GamificationController extends Notifier<GamificationState> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  GamificationState build() {
    Future.microtask(loadData);
    return GamificationState();
  }

  Future<void> loadData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final errors = <String>[];
    var badges = <UserBadge>[];
    GoodwillChainSummary? chainSummary;

    try {
      final badgesData = await _client
          .from('user_badges')
          .select('*, badges(*)')
          .eq('user_id', userId)
          .order('awarded_at', ascending: false);
      badges = badgesData.map((json) => UserBadge.fromJson(json)).toList();
    } catch (e) {
      errors.add('badges unavailable');
    }

    try {
      final chainData = await _client.rpc(
        'get_user_goodwill_chain',
        params: {'p_user_id': userId},
      );
      if (chainData != null) {
        chainSummary = GoodwillChainSummary.fromJson(
          chainData as Map<String, dynamic>,
        );
      }
    } catch (e) {
      errors.add('chain unavailable');
    }

    state = state.copyWith(
      badges: badges,
      chainSummary: chainSummary,
      isLoading: false,
      error: errors.isEmpty ? null : errors.join(', '),
    );
  }
}
