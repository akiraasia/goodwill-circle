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
    return _attachCreatorProfiles(campaigns);
  }

  Future<Campaign> getCampaignDetails(String campaignId) async {
    final data = await _client
        .from('campaigns')
        .select()
        .eq('id', campaignId)
        .single();
    final campaign = Campaign.fromJson(data);
    final campaigns = await _attachCreatorProfiles([campaign]);
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
        .select('*, profiles(name, photo_url)')
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false);
    return data.map((json) => CampaignDonation.fromJson(json)).toList();
  }
}
