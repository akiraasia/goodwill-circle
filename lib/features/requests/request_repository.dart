import 'dart:convert';

import 'package:flutter/services.dart';
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
    final currentUserId = _client.auth.currentUser?.id;
    final data = await _client
        .from('help_requests')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);

    final requests = data.map((json) => HelpRequest.fromJson(json)).toList();
    final starterRequests = await _fetchCommunityStarterRequests(currentUserId);
    final requestIds = requests.map((request) => request.id).toList();

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
        contactId: myVolunteer?['volunteer_id'] as String?,
      );
    }).toList();

    return _sortRequests([...starterRequests, ...hydratedRequests]);
  }

  Future<List<HelpRequest>> _fetchCommunityStarterRequests(
    String? currentUserId,
  ) async {
    try {
      final data = await _client
          .from('community_starter_requests')
          .select()
          .eq('status', 'open')
          .eq('allow_join_need', true)
          .order('created_at', ascending: false);

      final starterRequests = data
          .map((json) => HelpRequest.fromCommunityStarterJson(json))
          .toList();

      if (starterRequests.isNotEmpty) {
        return _hydrateStarterJoins(starterRequests, currentUserId);
      }
      return _loadBundledCommunityStarterRequests();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('community_starter_requests') ||
          message.contains('schema cache') ||
          message.contains('does not exist')) {
        return _loadBundledCommunityStarterRequests();
      }
      rethrow;
    }
  }

  Future<List<HelpRequest>> _loadBundledCommunityStarterRequests() async {
    final sql = await rootBundle.loadString('week13_schema.sql');
    final match = RegExp(
      r'FROM jsonb_to_recordset\(\$week13_requests\$\s*(.*?)\s*\$week13_requests\$::jsonb\)',
      dotAll: true,
    ).firstMatch(sql);
    if (match == null) return const [];

    final decoded = jsonDecode(match.group(1)!) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(HelpRequest.fromCommunityStarterJson)
        .toList();
  }

  Future<List<HelpRequest>> _hydrateStarterJoins(
    List<HelpRequest> starterRequests,
    String? currentUserId,
  ) async {
    if (currentUserId == null || starterRequests.isEmpty) {
      return starterRequests;
    }

    final requestIds = starterRequests.map((request) => request.id).toList();
    final joins = await _fetchCommunityStarterJoins(requestIds);
    final joinsByRequest = {
      for (final join in joins) join['request_id'] as String: join,
    };

    return starterRequests.map((request) {
      final join = joinsByRequest[request.id];
      if (join == null) return request;
      final contactChoice = join['contact_choice'];

      return request.copyWith(
        myVolunteerStatus: 'joined',
        communityJoinRole: join['join_role'] as String? ?? 'helpee',
        joinedContactOption: contactChoice is Map<String, dynamic>
            ? RequestContactOption.fromJson(contactChoice)
            : null,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCommunityStarterJoins(
    List<String> requestIds,
  ) async {
    try {
      return await _client
          .from('community_starter_request_joins')
          .select('request_id, join_role, contact_choice')
          .inFilter('request_id', requestIds);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('join_role') &&
          !message.contains('contact_choice') &&
          !message.contains('schema cache')) {
        rethrow;
      }
      return await _client
          .from('community_starter_request_joins')
          .select('request_id')
          .inFilter('request_id', requestIds);
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

  Future<void> volunteerForRequest(
    String requestId, {
    String? communityJoinRole,
    RequestContactOption? contactOption,
  }) async {
    if (requestId.startsWith('starter:')) return;

    final starterJoined = await _tryJoinCommunityStarterRequest(
      requestId,
      communityJoinRole: communityJoinRole,
      contactOption: contactOption,
    );
    if (starterJoined) return;

    final existing = await _client
        .from('request_volunteers')
        .select('id')
        .eq('request_id', requestId)
        .eq('volunteer_id', _client.auth.currentUser!.id)
        .maybeSingle();
    if (existing != null) return;

    try {
      await _client.rpc(
        'join_help_request',
        params: {
          'p_request_id': requestId,
          'p_join_role': communityJoinRole ?? 'helper',
          'p_contact_choice': contactOption?.toJson(),
        },
      );
    } catch (e) {
      // Fallback for when the RPC is not deployed yet.
      final message = e.toString().toLowerCase();
      if (!message.contains('function') && !message.contains('could not find')) {
        rethrow;
      }
      
      // 1. Add to request_volunteers (Fallback)
      await _client.from('request_volunteers').insert({
        'request_id': requestId,
        'volunteer_id': _client.auth.currentUser!.id,
      });

      // 2. Increment the volunteers_count on the request via an update.
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
  }

  Future<bool> _tryJoinCommunityStarterRequest(
    String requestId, {
    String? communityJoinRole,
    RequestContactOption? contactOption,
  }) async {
    try {
      await _client.rpc(
        'join_community_starter_request',
        params: {
          'p_request_id': requestId,
          'p_join_role': communityJoinRole ?? 'helpee',
          'p_contact_choice': contactOption?.toJson(),
        },
      );
      return true;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('p_join_role') ||
          message.contains('p_contact_choice') ||
          message.contains('function')) {
        return _tryJoinLegacyCommunityStarterRequest(requestId);
      }
      if (message.contains('community starter request not found') ||
          message.contains('schema cache')) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> _tryJoinLegacyCommunityStarterRequest(String requestId) async {
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

  Future<String?> completeRequest(
    String requestId,
    String participantId,
    String message,
  ) async {
    final result = await _client.rpc(
      'complete_connection',
      params: {
        'p_entity_id': requestId,
        'p_entity_type': 'request',
        'p_participant_id': participantId,
        'p_completion_message': message,
      },
    );
    return result as String?;
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
