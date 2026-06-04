import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(Supabase.instance.client);
});

class RequestRepository {
  final SupabaseClient _client;

  RequestRepository(this._client);

  Future<List<HelpRequest>> getOpenRequests() async {
    final data = await _client
        .from('help_requests')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);

    final requests = data.map((json) => HelpRequest.fromJson(json)).toList();
    final creatorIds = requests
        .map((request) => request.creatorId)
        .toSet()
        .toList();

    if (creatorIds.isEmpty) return requests;

    final profilesData = await _client
        .from('profiles')
        .select('id, name, photo_url')
        .inFilter('id', creatorIds);
    final profilesById = {
      for (final profile in profilesData) profile['id'] as String: profile,
    };

    return requests.map((request) {
      final profile = profilesById[request.creatorId];
      if (profile == null) return request;
      return request.copyWith(
        creatorName: profile['name'] as String?,
        creatorPhoto: profile['photo_url'] as String?,
      );
    }).toList();
  }

  Future<void> createRequest({
    required String title,
    required String description,
    required String category,
    required int reward,
  }) async {
    await _client.from('help_requests').insert({
      'creator_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'category': category,
      'goodwill_reward': reward,
    });
  }

  Future<void> volunteerForRequest(String requestId) async {
    // 1. Add to request_volunteers
    await _client.from('request_volunteers').insert({
      'request_id': requestId,
      'volunteer_id': _client.auth.currentUser!.id,
    });

    // 2. Increment the volunteers_count on the request via an RPC or update.
    // For simplicity, we can do a direct update if RLS allows, but typically we'd use an RPC for increment.
    // Assuming RLS allows it or we'll fetch existing and add 1 (Not ideal for concurrency, but okay for MVP).
    // Let's use standard update for now or better, ignore exact count if it's tricky without RPC.
    // Since we didn't write an increment RPC, we'll fetch and update for the MVP.
    final reqData = await _client
        .from('help_requests')
        .select('volunteers_count')
        .eq('id', requestId)
        .single();
    final currentCount = reqData['volunteers_count'] as int? ?? 0;

    await _client
        .from('help_requests')
        .update({'volunteers_count': currentCount + 1})
        .eq('id', requestId);
  }

  Future<void> completeRequest(String requestId) async {
    // Calls the secure RPC we defined in Week 3 schema
    await _client.rpc(
      'mark_request_completed',
      params: {'p_request_id': requestId},
    );
  }
}
