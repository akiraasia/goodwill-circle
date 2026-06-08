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
    await repairCurrentUserProfile();
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data != null) return Profile.fromJson(data);

    return _fallbackProfile(userId);
  }

  Future<void> repairCurrentUserProfile() async {
    try {
      await _client.rpc('repair_current_user_profile');
    } on PostgrestException {
      // Older schemas can still load the existing profile normally.
    }
  }

  Future<UserStats> getUserStats(String userId) async {
    final data = await _client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data != null) return UserStats.fromJson(data);

    return UserStats(
      userId: userId,
      credits: 50,
      trustScore: 0,
      impactScore: 0,
      helpCount: 0,
      campaignCount: 0,
      freeRequests: 1,
      creditsEarned: 0,
      creditsDonated: 0,
      campaignsSupported: 0,
      reputationScore: 0,
      updatedAt: DateTime.now(),
    );
  }

  Profile _fallbackProfile(String userId) {
    final user = _client.auth.currentUser;
    final metadataName =
        (user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'])
            ?.toString()
            .trim();
    final email = user?.email?.trim();
    final name = metadataName != null && metadataName.isNotEmpty
        ? metadataName
        : email != null && email.isNotEmpty
        ? email.split('@').first
        : 'Goodwill member';

    return Profile(
      id: userId,
      name: name,
      phone: user?.phone,
      createdAt: DateTime.now(),
    );
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
    required String linkedinUrl,
    required String phoneNumber,
    required String? profilePhotoUrl,
  }) async {
    await _client.rpc(
      'request_profile_strong_verification',
      params: {
        'p_account_type': accountType,
        'p_organization_name': organizationName,
        'p_linkedin_url': linkedinUrl,
        'p_phone_number': phoneNumber,
        'p_profile_photo_url': profilePhotoUrl,
      },
    );
  }
}
