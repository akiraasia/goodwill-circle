import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/confessions/models/confession.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final confessionRepositoryProvider = Provider<ConfessionRepository>((ref) {
  return ConfessionRepository(Supabase.instance.client);
});

class ConfessionRepository {
  final SupabaseClient _client;

  ConfessionRepository(this._client);

  Future<List<Confession>> getConfessions() async {
    final data = await _client
        .from('confessions')
        .select('id, content, image_url, support_count, created_at')
        .order('created_at', ascending: false);
    final confessions = data.map((json) => Confession.fromJson(json)).toList();
    return _attachSupportState(confessions);
  }

  Future<void> createConfession({
    required String content,
    String? imageUrl,
  }) async {
    await _client.from('confessions').insert({
      'author_id': _client.auth.currentUser!.id,
      'content': content,
      'image_url': imageUrl,
    });
  }

  Future<void> supportConfession(String confessionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('confession_supports').upsert({
      'confession_id': confessionId,
      'user_id': userId,
    }, onConflict: 'confession_id,user_id');
  }

  Future<List<Confession>> _attachSupportState(
    List<Confession> confessions,
  ) async {
    final userId = _client.auth.currentUser?.id;
    final confessionIds = confessions
        .map((confession) => confession.id)
        .toList();
    if (confessionIds.isEmpty) return confessions;

    try {
      final supportData = await _client
          .from('confession_supports')
          .select('confession_id, user_id')
          .inFilter('confession_id', confessionIds);
      final countsByConfession = <String, int>{};
      final supportedIds = <String>{};

      for (final support in supportData) {
        final confessionId = support['confession_id'] as String;
        countsByConfession[confessionId] =
            (countsByConfession[confessionId] ?? 0) + 1;
        if (userId != null && support['user_id'] == userId) {
          supportedIds.add(confessionId);
        }
      }

      return confessions.map((confession) {
        return confession.copyWith(
          supportCount:
              countsByConfession[confession.id] ?? confession.supportCount,
          isSupported: supportedIds.contains(confession.id),
        );
      }).toList();
    } on PostgrestException {
      return confessions;
    }
  }
}
