import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/profile/profile_repository.dart';
import 'package:goodwill_circle/shared/models/profile.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';

class ProfileState {
  final Profile? profile;
  final UserStats? stats;
  final bool isLoading;
  final String? error;

  ProfileState({this.profile, this.stats, this.isLoading = false, this.error});

  ProfileState copyWith({
    Profile? profile,
    UserStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    Future.microtask(loadProfile);
    return ProfileState();
  }

  Future<void> loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _repository.getProfile(userId);
      final stats = await _repository.getUserStats(userId);

      state = state.copyWith(profile: profile, stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile({String? name, String? bio, String? phone}) async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProfile = state.profile!.copyWith(
        name: name,
        bio: bio,
        phone: phone,
      );

      await _repository.updateProfile(updatedProfile);

      state = state.copyWith(profile: updatedProfile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
