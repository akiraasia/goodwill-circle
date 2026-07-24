import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'virtue_models.dart';

class VirtueHubRepository {
  final SupabaseClient _supabase;

  VirtueHubRepository(this._supabase);

  // ── Chat ─────────────────────────────────────────────────────────────────

  /// Fetch the latest 50 chat messages for a virtue room.
  Future<List<VirtueChatMessage>> getChatMessages(String virtueName) async {
    final response = await _supabase
        .from('wish_virtue_chat')
        .select()
        .eq('virtue_name', virtueName)
        .order('created_at', ascending: true)
        .limit(50);

    return (response as List<dynamic>)
        .map((e) => VirtueChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send a new chat message into a virtue room.
  Future<void> sendMessage({
    required String virtueName,
    required String message,
    required String senderName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('wish_virtue_chat').insert({
      'user_id': userId,
      'virtue_name': virtueName,
      'sender_name': senderName,
      'message': message,
    });
  }

  /// Subscribe to realtime chat for a virtue room.
  /// Returns a [RealtimeChannel] — caller must cancel on dispose.
  RealtimeChannel subscribeToChatRoom({
    required String virtueName,
    required void Function(VirtueChatMessage msg) onMessage,
  }) {
    return _supabase
        .channel('virtue-chat:$virtueName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wish_virtue_chat',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'virtue_name',
            value: virtueName,
          ),
          callback: (payload) {
            final msg = VirtueChatMessage.fromJson(
                payload.newRecord as Map<String, dynamic>);
            onMessage(msg);
          },
        )
        .subscribe();
  }

  // ── Materials ─────────────────────────────────────────────────────────────

  /// Fetch materials for a virtue board, newest first.
  Future<List<VirtueMaterial>> getMaterials(String virtueName) async {
    final response = await _supabase
        .from('wish_virtue_materials')
        .select()
        .eq('virtue_name', virtueName)
        .order('upvotes', ascending: false);

    return (response as List<dynamic>)
        .map((e) => VirtueMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Post a new material to a virtue board.
  Future<void> postMaterial({
    required String virtueName,
    required String materialType,
    required String title,
    String? description,
    String? url,
    String? imageUrl,
    required String posterName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('wish_virtue_materials').insert({
      'user_id': userId,
      'virtue_name': virtueName,
      'material_type': materialType,
      'title': title,
      'description': description,
      'url': url,
      'image_url': imageUrl,
      'poster_name': posterName,
    });
  }

  /// Upvote a material post
  Future<void> upvoteMaterial(String materialId) async {
    try {
      // Get current upvotes count
      final response = await _supabase
          .from('wish_virtue_materials')
          .select('upvotes')
          .eq('id', materialId)
          .single();

      final currentUpvotes = response['upvotes'] as int? ?? 0;

      // Update with incremented count
      await _supabase
          .from('wish_virtue_materials')
          .update({'upvotes': currentUpvotes + 1})
          .eq('id', materialId);
    } catch (e) {
      throw Exception('Failed to upvote material: $e');
    }
  }

  /// Subscribe to realtime materials for a virtue
  RealtimeChannel subscribeToMaterials({
    required String virtueName,
    required void Function(VirtueMaterial material) onMaterialAdded,
  }) {
    return _supabase
        .channel('virtue-materials:$virtueName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wish_virtue_materials',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'virtue_name',
            value: virtueName,
          ),
          callback: (payload) {
            final material = VirtueMaterial.fromJson(
                payload.newRecord as Map<String, dynamic>);
            onMaterialAdded(material);
          },
        )
        .subscribe();
  }
}

final virtueHubRepositoryProvider = Provider<VirtueHubRepository>((ref) {
  return VirtueHubRepository(Supabase.instance.client);
});

final virtueMaterialsProvider =
    FutureProvider.family<List<VirtueMaterial>, String>((ref, virtue) async {
  final repo = ref.read(virtueHubRepositoryProvider);
  return repo.getMaterials(virtue);
});

final virtueChatMessagesProvider =
    FutureProvider.family<List<VirtueChatMessage>, String>((ref, virtue) async {
  final repo = ref.read(virtueHubRepositoryProvider);
  return repo.getChatMessages(virtue);
});
