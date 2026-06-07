import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/shared/models/profile.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  Future<UserStats> getUserStats(String userId) async {
    final data = await _client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .single();
    return UserStats.fromJson(data);
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update({
          'name': profile.name,
          'bio': profile.bio,
          'photo_url': profile.photoUrl,
          'phone': profile.phone,
          'account_type': profile.accountType,
          'organization_name': profile.organizationName,
        })
        .eq('id', profile.id);
  }

  Future<void> requestVerification({
    required String accountType,
    required String? organizationName,
    required String note,
  }) async {
    await _client.rpc(
      'request_profile_verification',
      params: {
        'p_account_type': accountType,
        'p_organization_name': organizationName,
        'p_note': note,
      },
    );
  }
}
