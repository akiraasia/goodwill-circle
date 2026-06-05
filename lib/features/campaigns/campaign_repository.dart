import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign_update.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign_donation.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(Supabase.instance.client);
});

class CampaignRepository {
  final SupabaseClient _client;

  CampaignRepository(this._client);

  Future<List<Campaign>> getActiveCampaigns() async {
    final data = await _client
        .from('campaigns')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final campaigns = data.map((json) => Campaign.fromJson(json)).toList();
    return _attachMembershipState(await _attachCreatorProfiles(campaigns));
  }

  Future<Campaign> getCampaignDetails(String campaignId) async {
    final data = await _client
        .from('campaigns')
        .select()
        .eq('id', campaignId)
        .single();
    final campaign = Campaign.fromJson(data);
    final campaigns = await _attachMembershipState(
      await _attachCreatorProfiles([campaign]),
    );
    return campaigns.first;
  }

  Future<List<Campaign>> _attachCreatorProfiles(
    List<Campaign> campaigns,
  ) async {
    final creatorIds = campaigns
        .map((campaign) => campaign.creatorId)
        .toSet()
        .toList();

    if (creatorIds.isEmpty) return campaigns;

    final profilesData = await _client
        .from('profiles')
        .select('id, name, photo_url')
        .inFilter('id', creatorIds);
    final profilesById = {
      for (final profile in profilesData) profile['id'] as String: profile,
    };

    return campaigns.map((campaign) {
      final profile = profilesById[campaign.creatorId];
      if (profile == null) return campaign;
      return campaign.copyWith(
        creatorName: profile['name'] as String?,
        creatorPhoto: profile['photo_url'] as String?,
      );
    }).toList();
  }

  Future<void> createCampaign({
    required String title,
    required String description,
    required int goalAmount,
    DateTime? endDate,
  }) async {
    await _client.from('campaigns').insert({
      'creator_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'goal_amount': goalAmount,
      'end_date': endDate?.toIso8601String(),
    });
  }

  Future<void> donateToCampaign(String campaignId, int amount) async {
    // Calling the RPC created in week4_schema.sql
    await _client.rpc(
      'donate_to_campaign',
      params: {'p_campaign_id': campaignId, 'p_amount': amount},
    );
  }

  Future<void> joinCampaign(String campaignId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('campaign_members').upsert({
      'campaign_id': campaignId,
      'user_id': userId,
    }, onConflict: 'campaign_id,user_id');
  }

  Future<List<Campaign>> _attachMembershipState(
    List<Campaign> campaigns,
  ) async {
    final userId = _client.auth.currentUser?.id;
    final campaignIds = campaigns.map((campaign) => campaign.id).toList();
    if (campaignIds.isEmpty) return campaigns;

    try {
      final membersData = await _client
          .from('campaign_members')
          .select('campaign_id, user_id')
          .inFilter('campaign_id', campaignIds);
      final countsByCampaign = <String, int>{};
      final joinedCampaignIds = <String>{};

      for (final member in membersData) {
        final campaignId = member['campaign_id'] as String;
        countsByCampaign[campaignId] = (countsByCampaign[campaignId] ?? 0) + 1;
        if (userId != null && member['user_id'] == userId) {
          joinedCampaignIds.add(campaignId);
        }
      }

      return campaigns.map((campaign) {
        return campaign.copyWith(
          membersCount: countsByCampaign[campaign.id] ?? campaign.membersCount,
          isJoined: joinedCampaignIds.contains(campaign.id),
        );
      }).toList();
    } on PostgrestException {
      return campaigns;
    }
  }

  Future<List<CampaignUpdate>> getCampaignUpdates(String campaignId) async {
    final data = await _client
        .from('campaign_updates')
        .select('*')
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false);
    return data.map((json) => CampaignUpdate.fromJson(json)).toList();
  }

  Future<List<CampaignDonation>> getCampaignDonations(String campaignId) async {
    final data = await _client
        .from('campaign_donations')
        .select()
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false);
    final donations = data
        .map((json) => CampaignDonation.fromJson(json))
        .toList();
    return _attachDonorProfiles(donations);
  }

  Future<List<CampaignDonation>> _attachDonorProfiles(
    List<CampaignDonation> donations,
  ) async {
    final donorIds = donations
        .map((donation) => donation.donorId)
        .toSet()
        .toList();

    if (donorIds.isEmpty) return donations;

    final profilesData = await _client
        .from('profiles')
        .select('id, name, photo_url')
        .inFilter('id', donorIds);
    final profilesById = {
      for (final profile in profilesData) profile['id'] as String: profile,
    };

    return donations.map((donation) {
      final profile = profilesById[donation.donorId];
      if (profile == null) return donation;
      return donation.copyWith(
        donorName: profile['name'] as String?,
        donorPhoto: profile['photo_url'] as String?,
      );
    }).toList();
  }
}
