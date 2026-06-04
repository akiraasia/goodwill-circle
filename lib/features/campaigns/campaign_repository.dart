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
        .select('*, profiles(name, photo_url)')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return data.map((json) => Campaign.fromJson(json)).toList();
  }

  Future<Campaign> getCampaignDetails(String campaignId) async {
    final data = await _client
        .from('campaigns')
        .select('*, profiles(name, photo_url)')
        .eq('id', campaignId)
        .single();
    return Campaign.fromJson(data);
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
