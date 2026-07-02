import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:goodwill_circle/features/requests/models/help_request_post.dart';

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

      // Calculate actual helper and helpie counts from volunteers
      int helperCount = 0;
      int helpieCount = 0;
      var creatorAlreadyCountedAsHelpie = false;
      for (final volunteer in volunteers) {
        final role = volunteer['join_role'] as String? ?? 'helper';
        if (role == 'helper') {
          helperCount++;
        } else if (role == 'helpee') {
          helpieCount++;
          if (volunteer['volunteer_id'] == request.creatorId) {
            creatorAlreadyCountedAsHelpie = true;
          }
        }
      }
      final visibleHelpieCount =
          helpieCount + (creatorAlreadyCountedAsHelpie ? 0 : 1);

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
        communityJoinRole: myVolunteer?['join_role'] as String?,
        helperCount: helperCount,
        helpieCount: visibleHelpieCount,
        volunteersCount: helperCount + visibleHelpieCount,
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
    if (starterRequests.isEmpty) {
      return starterRequests;
    }

    final requestIds = starterRequests.map((request) => request.id).toList();
    final joins = await _fetchCommunityStarterJoins(requestIds, currentUserId);
    final joinsByRequest = <String, List<Map<String, dynamic>>>{};
    for (final join in joins) {
      final requestId = join['request_id'] as String;
      joinsByRequest.putIfAbsent(requestId, () => []).add(join);
    }

    return starterRequests.map((request) {
      final requestJoins = joinsByRequest[request.id] ?? const [];
      final helperCount = requestJoins
          .where(
            (join) => (join['join_role'] as String? ?? 'helpee') == 'helper',
          )
          .length;
      final helpieCount = requestJoins
          .where(
            (join) => (join['join_role'] as String? ?? 'helpee') == 'helpee',
          )
          .length;
      Map<String, dynamic>? myJoin;
      if (currentUserId != null) {
        for (final join in requestJoins) {
          if (join['user_id'] == currentUserId) {
            myJoin = join;
            break;
          }
        }
      }
      final contactChoice = myJoin?['contact_choice'];
      final joinedOption = contactChoice is Map<String, dynamic>
          ? RequestContactOption.fromJson(contactChoice)
          : null;

      if (myJoin == null) {
        return request.copyWith(
          helperCount: helperCount,
          helpieCount: helpieCount,
          volunteersCount: helperCount + helpieCount,
        );
      }

      return request.copyWith(
        myVolunteerStatus: 'joined',
        communityJoinRole: myJoin['join_role'] as String? ?? 'helpee',
        joinedContactOption: joinedOption,
        helperCount: helperCount,
        helpieCount: helpieCount,
        volunteersCount: helperCount + helpieCount,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCommunityStarterJoins(
    List<String> requestIds,
    String? currentUserId,
  ) async {
    try {
      var query = _client
          .from('community_starter_request_joins')
          .select('request_id, user_id, join_role, contact_choice, join_type')
          .inFilter('request_id', requestIds);
      if (currentUserId == null) {
        return await query;
      }
      return await query;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('join_role') &&
          !message.contains('contact_choice') &&
          !message.contains('user_id') &&
          !message.contains('schema cache')) {
        rethrow;
      }
      var query = _client
          .from('community_starter_request_joins')
          .select('request_id, user_id')
          .inFilter('request_id', requestIds);
      if (currentUserId == null) {
        return await query;
      }
      return await query;
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
          .select(
            'request_id, volunteer_id, status, completion_message, join_role, contact_choice, join_type',
          )
          .inFilter('request_id', requestIds);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('join_role') ||
          message.contains('contact_choice') ||
          message.contains('join_type') ||
          message.contains('completion_message')) {
        return _client
            .from('request_volunteers')
            .select('request_id, volunteer_id, status')
            .inFilter('request_id', requestIds);
      }
      rethrow;
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
    bool isCommunityRequest = false,
    String? communityJoinRole,
    RequestContactOption? contactOption,
    String? joinType,
  }) async {
    if (isCommunityRequest || requestId.startsWith('starter:')) {
      final joined = await _tryJoinCommunityStarterRequest(
        requestId,
        communityJoinRole: communityJoinRole,
        contactOption: contactOption,
        joinType: joinType,
      );
      if (!joined) {
        throw StateError(
          'Connection Hub is unavailable for this starter request.',
        );
      }
      return;
    }

    final existing = await _fetchCurrentRequestVolunteer(requestId);
    if (existing != null &&
        existing['join_role'] == (communityJoinRole ?? 'helper') &&
        (existing['join_type'] as String? ?? 'individual') ==
            (joinType ?? 'individual') &&
        _contactChoiceEquals(existing['contact_choice'], contactOption)) {
      return;
    }

    try {
      await _client.rpc(
        'join_help_request',
        params: {
          'p_request_id': requestId,
          'p_join_role': communityJoinRole ?? 'helper',
          'p_contact_choice': contactOption?.toJson(),
          'p_join_type': joinType ?? 'individual',
        },
      );
    } catch (e) {
      // Fallback for older RPC
      final message = e.toString().toLowerCase();
      if (_shouldTryCommunityStarterJoin(e)) {
        final joined = await _tryJoinCommunityStarterRequest(
          requestId,
          communityJoinRole: communityJoinRole,
          contactOption: contactOption,
          joinType: joinType,
        );
        if (joined) return;
      }

      if (message.contains('p_join_type') || message.contains('parameter')) {
        try {
          await _client.rpc(
            'join_help_request',
            params: {
              'p_request_id': requestId,
              'p_join_role': communityJoinRole ?? 'helper',
              'p_contact_choice': contactOption?.toJson(),
            },
          );
          return;
        } catch (_) {}
      }

      try {
        await _upsertRequestVolunteerFallback(
          requestId,
          communityJoinRole: communityJoinRole,
          contactOption: contactOption,
          joinType: joinType,
        );
      } catch (fallbackError) {
        if (_shouldTryCommunityStarterJoin(fallbackError)) {
          final joined = await _tryJoinCommunityStarterRequest(
            requestId,
            communityJoinRole: communityJoinRole,
            contactOption: contactOption,
            joinType: joinType,
          );
          if (joined) return;
        }
        rethrow;
      }

      final rows = await _client
          .from('request_volunteers')
          .select('join_role')
          .eq('request_id', requestId);
      final helperCount = rows
          .where((row) => (row['join_role'] as String? ?? 'helper') == 'helper')
          .length;
      final helpieCount = rows
          .where((row) => (row['join_role'] as String? ?? 'helper') == 'helpee')
          .length;

      await _syncRequestJoinCounts(
        requestId,
        helperCount: helperCount,
        helpieCount: helpieCount + 1,
      );
    }
  }

  Future<void> _upsertRequestVolunteerFallback(
    String requestId, {
    String? communityJoinRole,
    RequestContactOption? contactOption,
    String? joinType,
  }) async {
    final payload = {
      'request_id': requestId,
      'volunteer_id': _client.auth.currentUser!.id,
      'status': 'accepted',
      'join_role': communityJoinRole ?? 'helper',
      'contact_choice': contactOption?.toJson(),
      'join_type': joinType ?? 'individual',
    };

    try {
      await _client
          .from('request_volunteers')
          .upsert(payload, onConflict: 'request_id,volunteer_id');
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('join_role') &&
          !message.contains('contact_choice') &&
          !message.contains('join_type') &&
          !message.contains('schema cache')) {
        rethrow;
      }
      await _client.from('request_volunteers').upsert({
        'request_id': requestId,
        'volunteer_id': _client.auth.currentUser!.id,
        'status': 'accepted',
      }, onConflict: 'request_id,volunteer_id');
    }
  }

  Future<void> _syncRequestJoinCounts(
    String requestId, {
    required int helperCount,
    required int helpieCount,
  }) async {
    try {
      await _client
          .from('help_requests')
          .update({
            'volunteers_count': helperCount + helpieCount,
            'join_count': helpieCount,
            'helper_count': helperCount,
            'helpie_count': helpieCount,
          })
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('join_count') &&
          !message.contains('helper_count') &&
          !message.contains('helpie_count') &&
          !message.contains('schema cache')) {
        rethrow;
      }
      await _client
          .from('help_requests')
          .update({'volunteers_count': helperCount + helpieCount})
          .eq('id', requestId);
    }
  }

  Future<bool> _tryJoinCommunityStarterRequest(
    String requestId, {
    String? communityJoinRole,
    RequestContactOption? contactOption,
    String? joinType,
  }) async {
    try {
      await _client.rpc(
        'join_community_starter_request',
        params: {
          'p_request_id': requestId,
          'p_join_role': communityJoinRole ?? 'helpee',
          'p_contact_choice': contactOption?.toJson(),
          'p_join_type': joinType ?? 'individual',
        },
      );
      return true;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('p_join_type') ||
          message.contains('parameter') ||
          message.contains('function')) {
        return _tryJoinLegacyCommunityStarterRequest(
          requestId,
          communityJoinRole: communityJoinRole,
          contactOption: contactOption,
        );
      }
      if (message.contains('community starter request not found') ||
          message.contains('invalid input syntax') ||
          message.contains('invalid uuid') ||
          message.contains('schema cache')) {
        return false;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchCurrentRequestVolunteer(
    String requestId,
  ) async {
    try {
      return await _client
          .from('request_volunteers')
          .select('id, join_role, join_type, contact_choice')
          .eq('request_id', requestId)
          .eq('volunteer_id', _client.auth.currentUser!.id)
          .maybeSingle();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('join_role') &&
          !message.contains('join_type') &&
          !message.contains('contact_choice') &&
          !message.contains('schema cache')) {
        rethrow;
      }
      return await _client
          .from('request_volunteers')
          .select('id')
          .eq('request_id', requestId)
          .eq('volunteer_id', _client.auth.currentUser!.id)
          .maybeSingle();
    }
  }

  Future<bool> _tryJoinLegacyCommunityStarterRequest(
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
        try {
          await _client.rpc(
            'join_community_starter_request',
            params: {'p_request_id': requestId},
          );
          return true;
        } catch (_) {
          return false;
        }
      }
      rethrow;
    }
  }

  Future<List<HelpRequestPost>> getRequestPosts(String requestId) async {
    try {
      // If it is a starter request that is local only (offline fallback), return empty posts
      if (requestId.startsWith('starter:')) return const [];

      final data = await _client
          .from('help_request_posts')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: true);

      final posts = data.map((json) => HelpRequestPost.fromJson(json)).toList();
      if (posts.isEmpty) return const [];

      final userIds = posts.map((post) => post.userId).toSet().toList();
      final profilesData = await _fetchProfiles(userIds);
      final profilesById = {
        for (final profile in profilesData) profile['id'] as String: profile,
      };

      return posts.map((post) {
        final profile = profilesById[post.userId];
        return post.copyWith(
          userName: profile?['name'] as String?,
          userPhoto: _publicPhotoUrl(profile),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addRequestPost(String requestId, String message) async {
    if (requestId.startsWith('starter:')) return;
    final trimmedMessage = message.trim();
    final userId = _client.auth.currentUser?.id;
    if (userId == null || trimmedMessage.isEmpty) return;

    await _client.from('help_request_posts').insert({
      'request_id': requestId,
      'user_id': userId,
      'message': trimmedMessage,
    });
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

  Future<int> toggleSupport(String requestId) async {
    final result = await _client.rpc(
      'toggle_support',
      params: {'p_entity_id': requestId, 'p_entity_type': 'request'},
    );
    return result as int;
  }

  Future<List<Map<String, dynamic>>> fetchContacts(
    String requestId,
    String myRole,
  ) async {
    List<Map<String, dynamic>> rpcContacts = const [];

    try {
      final result = await _client.rpc(
        'get_entity_contacts',
        params: {
          'p_entity_id': requestId,
          'p_entity_type': 'request',
          'p_my_role': myRole,
        },
      );
      rpcContacts = List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      if (requestId.startsWith('starter:')) {
        rethrow;
      }
    }

    if (requestId.startsWith('starter:')) {
      return rpcContacts;
    }

    final fallbackContacts = await _fetchRequestContactsFallback(requestId);
    if (fallbackContacts.isEmpty) {
      return rpcContacts;
    }
    if (rpcContacts.isEmpty) {
      return fallbackContacts;
    }

    return _mergeContactRows(fallbackContacts, rpcContacts);
  }

  Future<List<Map<String, dynamic>>> _fetchRequestContactsFallback(
    String requestId,
  ) async {
    if (!_looksLikeUuid(requestId)) {
      return const [];
    }

    final starterContacts = await _fetchStarterContactRows(requestId);
    if (starterContacts.isNotEmpty) {
      return starterContacts;
    }

    Map<String, dynamic>? request;
    try {
      request = await _client
          .from('help_requests')
          .select('creator_id')
          .eq('id', requestId)
          .maybeSingle();
    } on PostgrestException {
      return const [];
    }

    if (request == null) {
      return const [];
    }

    final volunteers = await _fetchRequestVolunteers([requestId]);
    final profileIds = <String>{
      request['creator_id'] as String,
      ...volunteers.map((volunteer) => volunteer['volunteer_id'] as String),
    }.toList();
    final profiles = await _fetchProfiles(profileIds);
    final profilesById = {
      for (final profile in profiles) profile['id'] as String: profile,
    };

    return [
      _contactRow(
        participantId: request['creator_id'] as String,
        profile: profilesById[request['creator_id']],
        status: 'accepted',
        joinType: 'individual',
        role: 'helpee',
      ),
      ...volunteers.map((volunteer) {
        final userId = volunteer['volunteer_id'] as String;
        return _contactRow(
          participantId: userId,
          profile: profilesById[userId],
          status: volunteer['status'] as String? ?? 'accepted',
          joinType: volunteer['join_type'] as String? ?? 'individual',
          role: volunteer['join_role'] as String? ?? 'helper',
        );
      }),
    ];
  }

  Future<List<Map<String, dynamic>>> _fetchStarterContactRows(
    String requestId,
  ) async {
    try {
      final starter = await _client
          .from('community_starter_requests')
          .select('id')
          .eq('id', requestId)
          .maybeSingle();
      if (starter == null) {
        return const [];
      }

      final joins = await _fetchCommunityStarterJoins(
        [requestId],
        _client.auth.currentUser?.id,
      );
      if (joins.isEmpty) {
        return const [];
      }

      final profileIds = joins.map((join) => join['user_id'] as String).toList();
      final profiles = await _fetchProfiles(profileIds);
      final profilesById = {
        for (final profile in profiles) profile['id'] as String: profile,
      };

      return joins.map((join) {
        final userId = join['user_id'] as String;
        return _contactRow(
          participantId: userId,
          profile: profilesById[userId],
          status: 'accepted',
          joinType: join['join_type'] as String? ?? 'individual',
          role: join['join_role'] as String? ?? 'helpee',
        );
      }).toList();
    } on PostgrestException {
      return const [];
    }
  }

  Map<String, dynamic> _contactRow({
    required String participantId,
    required Map<String, dynamic>? profile,
    required String status,
    required String joinType,
    required String role,
  }) {
    return {
      'participant_id': participantId,
      'name': profile?['name'] as String? ?? 'Unknown',
      'email': '',
      'phone': profile?['phone'] as String? ?? '',
      'status': status,
      'join_type': joinType,
      'role': role,
    };
  }

  List<Map<String, dynamic>> _mergeContactRows(
    List<Map<String, dynamic>> baseRows,
    List<Map<String, dynamic>> enrichedRows,
  ) {
    final rowsById = {
      for (final row in baseRows) row['participant_id'] as String: row,
    };

    for (final enriched in enrichedRows) {
      final id = enriched['participant_id'] as String?;
      if (id == null) continue;
      final base = rowsById[id];
      if (base == null) {
        rowsById[id] = enriched;
        continue;
      }
      rowsById[id] = {
        ...base,
        if ((enriched['name'] as String?)?.trim().isNotEmpty == true)
          'name': enriched['name'],
        if ((enriched['email'] as String?)?.trim().isNotEmpty == true)
          'email': enriched['email'],
        if ((enriched['phone'] as String?)?.trim().isNotEmpty == true)
          'phone': enriched['phone'],
        if ((enriched['status'] as String?)?.trim().isNotEmpty == true)
          'status': enriched['status'],
      };
    }

    final rows = rowsById.values.toList();
    rows.sort((a, b) {
      final roleCompare = (a['role'] as String).compareTo(b['role'] as String);
      if (roleCompare != 0) return roleCompare;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return rows;
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  bool _shouldTryCommunityStarterJoin(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('help request not found') ||
        message.contains('not found or not open') ||
        message.contains('request_volunteers_request_id_fkey') ||
        message.contains('key is not present in table "help_requests"')) {
      return true;
    }
    return error is PostgrestException && error.code == '23503';
  }

  bool _contactChoiceEquals(
    dynamic currentValue,
    RequestContactOption? contactOption,
  ) {
    if (contactOption == null) {
      return currentValue == null;
    }
    if (currentValue is! Map<String, dynamic>) {
      return false;
    }
    return jsonEncode(currentValue) == jsonEncode(contactOption.toJson());
  }
}
