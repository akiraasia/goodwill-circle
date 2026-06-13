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
    final starterRequests = await _fetchCommunityStarterRequests();
    final requestIds = requests.map((request) => request.id).toList();
    final currentUserId = _client.auth.currentUser?.id;

    final volunteersData = requestIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _fetchRequestVolunteers(requestIds);

    final profileIds = {
      ...requests
          .where((request) => !request.isCommunityRequest)
          .map((request) => request.creatorId),
      ...volunteersData.map((volunteer) => volunteer['volunteer_id'] as String),
    }.toList();

    if (profileIds.isEmpty) return _sortRequests([...starterRequests]);

    final profilesData = await _fetchProfiles(profileIds);
    final profilesById = {
      for (final profile in profilesData) profile['id'] as String: profile,
    };
    final volunteersByRequest = <String, List<Map<String, dynamic>>>{};
    for (final volunteer in volunteersData) {
      final requestId = volunteer['request_id'] as String;
      volunteersByRequest.putIfAbsent(requestId, () => []).add(volunteer);
    }

    final hydratedRequests = requests.map((request) {
      final creatorProfile = profilesById[request.creatorId];
      final volunteers = volunteersByRequest[request.id] ?? const [];
      Map<String, dynamic>? myVolunteer;
      for (final volunteer in volunteers) {
        if (volunteer['volunteer_id'] == currentUserId) {
          myVolunteer = volunteer;
          break;
        }
      }

      Map<String, dynamic>? contactProfile;
      if (currentUserId == request.creatorId && volunteers.isNotEmpty) {
        final selectedVolunteer = volunteers.firstWhere(
          (volunteer) => volunteer['status'] == 'completion_requested',
          orElse: () => volunteers.first,
        );
        contactProfile = profilesById[selectedVolunteer['volunteer_id']];
        myVolunteer = selectedVolunteer;
      } else if (currentUserId != request.creatorId) {
        contactProfile = creatorProfile;
      }

      return request.copyWith(
        creatorName: creatorProfile?['name'] as String?,
        creatorPhoto: _publicPhotoUrl(creatorProfile),
        creatorPhone: creatorProfile?['phone'] as String?,
        creatorVerificationStatus:
            creatorProfile?['verification_status'] as String?,
        contactName: contactProfile?['name'] as String?,
        contactPhoto: _publicPhotoUrl(contactProfile),
        contactPhone: contactProfile?['phone'] as String?,
        myVolunteerStatus: myVolunteer?['status'] as String?,
        completionMessage: myVolunteer?['completion_message'] as String?,
      );
    }).toList();

    return _sortRequests([...starterRequests, ...hydratedRequests]);
  }

  Future<List<HelpRequest>> _fetchCommunityStarterRequests() async {
    try {
      final data = await _client
          .from('community_starter_requests')
          .select()
          .eq('status', 'open')
          .eq('allow_join_need', true)
          .order('created_at', ascending: false);

      return data
          .map((json) => HelpRequest.fromCommunityStarterJson(json))
          .toList();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('community_starter_requests') ||
          message.contains('schema cache') ||
          message.contains('does not exist')) {
        return const [];
      }
      rethrow;
    }
  }

  List<HelpRequest> _sortRequests(List<HelpRequest> requests) {
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<List<Map<String, dynamic>>> _fetchRequestVolunteers(
    List<String> requestIds,
  ) async {
    try {
      return await _client
          .from('request_volunteers')
          .select('request_id, volunteer_id, status, completion_message')
          .inFilter('request_id', requestIds);
    } on PostgrestException catch (e) {
      if (!e.message.toLowerCase().contains('completion_message')) rethrow;
      return _client
          .from('request_volunteers')
          .select('request_id, volunteer_id, status')
          .inFilter('request_id', requestIds);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProfiles(List<String> ids) async {
    try {
      return await _client
          .from('profiles')
          .select(
            'id, name, photo_url, profile_photo_public, phone, verification_status',
          )
          .inFilter('id', ids);
    } on PostgrestException catch (e) {
      if (!e.message.toLowerCase().contains('phone') &&
          !e.message.toLowerCase().contains('verification_status') &&
          !e.message.toLowerCase().contains('profile_photo_public')) {
        rethrow;
      }
      return _client
          .from('profiles')
          .select('id, name, photo_url')
          .inFilter('id', ids);
    }
  }

  String? _publicPhotoUrl(Map<String, dynamic>? profile) {
    if (profile == null || profile['profile_photo_public'] != true) {
      return null;
    }
    return profile['photo_url'] as String?;
  }

  Future<String> createRequest({
    required String title,
    required String description,
    required String category,
    required int reward,
    String? imageUrl,
  }) async {
    final payload = {
      'creator_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'category': category,
      'goodwill_reward': reward,
      'image_url': imageUrl,
    };

    try {
      final row = await _client
          .from('help_requests')
          .insert(payload)
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (e) {
      if (!e.message.toLowerCase().contains('image_url')) rethrow;
      payload.remove('image_url');
      final row = await _client
          .from('help_requests')
          .insert(payload)
          .select('id')
          .single();
      return row['id'] as String;
    }
  }

  Future<void> volunteerForRequest(String requestId) async {
    final starterJoined = await _tryJoinCommunityStarterRequest(requestId);
    if (starterJoined) return;

    final existing = await _client
        .from('request_volunteers')
        .select('id')
        .eq('request_id', requestId)
        .eq('volunteer_id', _client.auth.currentUser!.id)
        .maybeSingle();
    if (existing != null) return;

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

  Future<bool> _tryJoinCommunityStarterRequest(String requestId) async {
    try {
      await _client.rpc(
        'join_community_starter_request',
        params: {'p_request_id': requestId},
      );
      return true;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('function') ||
          message.contains('community starter request not found') ||
          message.contains('schema cache')) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> completeRequest(String requestId) async {
    // Calls the secure RPC we defined in Week 3 schema
    await _client.rpc(
      'mark_request_completed',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> requestCompletionReview({
    required String requestId,
    String? message,
  }) async {
    await _client.rpc(
      'request_help_completion_review',
      params: {'p_request_id': requestId, 'p_message': message},
    );
  }
}
