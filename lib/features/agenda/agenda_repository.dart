import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/agenda/models/nonprofit_agenda_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(Supabase.instance.client);
});

class AgendaRepository {
  final SupabaseClient _client;

  AgendaRepository(this._client);

  Future<List<NonprofitAgendaItem>> getOpenAgendaItems() async {
    final data = await _client
        .from('nonprofit_agenda_items')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);

    final items = data
        .map((json) => NonprofitAgendaItem.fromJson(json))
        .toList();
    final ngoIds = items.map((item) => item.ngoId).toSet().toList();
    final verificationByNgoId = <String, String>{};
    if (ngoIds.isNotEmpty) {
      try {
        final profilesData = await _client
            .from('profiles')
            .select('id, verification_status')
            .inFilter('id', ngoIds);
        for (final profile in profilesData) {
          verificationByNgoId[profile['id'] as String] =
              profile['verification_status'] as String? ?? 'unverified';
        }
      } on PostgrestException {
        // Older schemas may not have verification columns yet.
      }
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null || items.isEmpty) {
      return items
          .map(
            (item) => item.copyWith(
              ngoVerificationStatus:
                  verificationByNgoId[item.ngoId] ?? 'unverified',
            ),
          )
          .toList();
    }

    final participantData = await _client
        .from('agenda_participants')
        .select('agenda_item_id, status, join_role')
        .eq('volunteer_id', userId)
        .inFilter('agenda_item_id', items.map((item) => item.id).toList());

    final statusByAgendaId = {
      for (final participant in participantData)
        participant['agenda_item_id'] as String: participant['status'] as String,
    };

    // Calculate helper and helpie counts for all agenda items
    final agendaIds = items.map((item) => item.id).toList();
    final allParticipantsData = await _client
        .from('agenda_participants')
        .select('agenda_item_id, join_role')
        .inFilter('agenda_item_id', agendaIds);
    
    final helperCountsByAgenda = <String, int>{};
    final helpieCountsByAgenda = <String, int>{};
    
    for (final participant in allParticipantsData) {
      final agendaId = participant['agenda_item_id'] as String;
      final role = participant['join_role'] as String? ?? 'helper';
      if (role == 'helper') {
        helperCountsByAgenda[agendaId] = (helperCountsByAgenda[agendaId] ?? 0) + 1;
      } else if (role == 'helpee') {
        helpieCountsByAgenda[agendaId] = (helpieCountsByAgenda[agendaId] ?? 0) + 1;
      }
    }

    return items
        .map(
          (item) => item.copyWith(
            ngoVerificationStatus:
                verificationByNgoId[item.ngoId] ?? 'unverified',
            myParticipantStatus: statusByAgendaId[item.id],
            helperCount: helperCountsByAgenda[item.id] ?? item.helperCount,
            helpieCount: helpieCountsByAgenda[item.id] ?? item.helpieCount,
          ),
        )
        .toList();
  }

  Future<void> createAgendaItem({
    required String ngoName,
    required String title,
    required String description,
    required String skillArea,
    required String location,
    required int seatsNeeded,
    required String rewardBadgeId,
    required String certificateTitle,
    required String certificateIssuer,
    String? imageUrl,
  }) async {
    await _client.from('nonprofit_agenda_items').insert({
      'ngo_id': _client.auth.currentUser!.id,
      'ngo_name': ngoName,
      'title': title,
      'description': description,
      'skill_area': skillArea,
      'location': location,
      'seats_needed': seatsNeeded,
      'reward_badge_id': rewardBadgeId,
      'certificate_title': certificateTitle,
      'certificate_issuer': certificateIssuer,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  Future<void> joinAgendaItem(String agendaItemId, String role) async {
    await _client.rpc(
      'join_nonprofit_agenda_item',
      params: {'p_agenda_item_id': agendaItemId, 'p_role': role},
    );
  }

  Future<int> toggleSupport(String agendaId) async {
    final result = await _client.rpc(
      'toggle_support',
      params: {'p_entity_id': agendaId, 'p_entity_type': 'agenda'},
    );
    return result as int;
  }

  Future<List<Map<String, dynamic>>> fetchContacts(String agendaId, String myRole) async {
    final result = await _client.rpc(
      'get_entity_contacts',
      params: {
        'p_entity_id': agendaId,
        'p_entity_type': 'agenda',
        'p_my_role': myRole,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }
}
