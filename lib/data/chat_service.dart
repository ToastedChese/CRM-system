import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import 'supabase_service.dart';

class ChatService {
  static sp.SupabaseClient get _db => sp.Supabase.instance.client;

  // ───────────────────────── Conversations ─────────────────────────

  /// Conversations visible to the current user. (RLS enforces membership)
  static Future<List<Map<String, dynamic>>> myConversations() async {
    final res = await _db
        .from('conversations')
        .select('id, title, is_group, created_by, created_at')
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> conversation(int id) async {
    final res = await _db
        .from('conversations')
        .select('id, title, is_group, created_by, created_at')
        .eq('id', id)
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> getOrCreateDm({
    required String otherUserId,
  }) async {
    final res = await _db.rpc(
      'get_or_create_dm_rpc',
      params: {'p_other': otherUserId},
    );
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> createGroup({
    String? title,
    required List<String> participantUserIds,
  }) async {
    final res = await _db.rpc(
      'create_group_conversation_rpc',
      params: {
        'p_title': (title ?? '').trim(),
        'p_participants': participantUserIds,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateConversationTitle({
    required int conversationId,
    required String title,
  }) async {
    final res = await _db
        .from('conversations')
        .update({'title': title})
        .eq('id', conversationId)
        .select('id, title, is_group, created_by, created_at')
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────────────────────── Participants ─────────────────────────

  /// Uses enriched view: (conversation_id, user_id, display_name, email, avatar_url)
  static Future<List<Map<String, dynamic>>> participants(
    int conversationId,
  ) async {
    final res = await _db
        .from('conversation_participants_enriched')
        .select('conversation_id, user_id, display_name, email, avatar_url')
        .eq('conversation_id', conversationId);
    final list = (res as List).cast<Map<String, dynamic>>();
    // Fallback: if avatar_url is missing, try resolve via profile tables
    for (final m in list) {
      final current = (m['avatar_url'] ?? '').toString();
      if (current.isEmpty) {
        final uid = (m['user_id'] ?? '').toString();
        if (uid.isNotEmpty) {
          try {
            final url = await SupabaseService.avatarByAuthUserId(uid);
            if (url != null && url.isNotEmpty) {
              m['avatar_url'] = url;
            }
          } catch (_) {}
        }
      }
    }
    return list;
  }

  static Future<void> addParticipant({
    required int conversationId,
    required String userId,
  }) async {
    await _db.from('conversation_participants').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': 'member',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> addParticipants({
    required int conversationId,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return;
    final rows = userIds
        .map(
          (u) => {
            'conversation_id': conversationId,
            'user_id': u,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          },
        )
        .toList();
    await _db.from('conversation_participants').insert(rows);
  }

  static Future<void> removeParticipant({
    required int conversationId,
    required String userId,
  }) async {
    await _db
        .from('conversation_participants')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  /// Directory the picker searches (view must return user_id, display_name, email, avatar_url)
  static Future<List<Map<String, dynamic>>> searchDirectory(
    String query,
  ) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final res = await _db
        .from('directory_allowed_contacts')
        .select('user_id, display_name, email, avatar_url')
        .or('display_name.ilike.%$q%,email.ilike.%$q%')
        .order('display_name')
        .limit(25);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ───────────────────────── Messages ─────────────────────────

  /// Matches schema: sender_id is the sender (uuid)
  static Future<List<Map<String, dynamic>>> messages(
    int conversationId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _db
        .from('messages')
        .select('id, conversation_id, sender_id, body, attachments, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .range(offset, offset + limit - 1);
    return (res as List).cast<Map<String, dynamic>>();
  }

  ///last-message preview on the list screen
  static Future<Map<String, dynamic>?> lastMessage(int conversationId) async {
    final res = await _db
        .from('messages')
        .select('id, conversation_id, sender_id, body, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return (res == null) ? null : Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String body,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final row = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_id': _db.auth.currentUser!.id,
      'body': body,
      if (attachments != null) 'attachments': attachments,
    };
    final res = await _db
        .from('messages')
        .insert(row)
        .select('id, conversation_id, sender_id, body, attachments, created_at')
        .single();

    final map = Map<String, dynamic>.from(res as Map);
    // DEBUG: log the server-returned message row
    try {
      print('DEBUG: ChatService.sendMessage returned: $map');
    } catch (_) {}
    return map;
  }

  /// Subscribe to ALL message inserts (no filter). Caller must filter as needed.
  static sp.RealtimeChannel subscribeAllMessages({
    required void Function(Map<String, dynamic> newRow) onInsert,
  }) {
    final channel = _db.channel('messages_global');
    channel.onPostgresChanges(
      event: sp.PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final r = Map<String, dynamic>.from(payload.newRecord);
        // DEBUG: log global incoming message row
        try {
          print('DEBUG: Global message insert received: $r');
        } catch (_) {}
        onInsert(r);
      },
    );
    channel.subscribe();
    return channel;
  }

  static sp.RealtimeChannel subscribeMessages({
    required int conversationId,
    required void Function(Map<String, dynamic> newRow) onInsert,
  }) {
    final channel = _db.channel('messages_conv_$conversationId');
    channel.onPostgresChanges(
      event: sp.PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: sp.PostgresChangeFilter(
        type: sp.PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId.toString(),
      ),
      callback: (payload) {
        final r = Map<String, dynamic>.from(payload.newRecord);
        // DEBUG: log per-conversation incoming message row
        try {
          print('DEBUG: Conversation $conversationId insert: $r');
        } catch (_) {}
        onInsert(r);
      },
    );
    channel.subscribe();
    return channel;
  }

  /// Return true if the supplied userId is a participant in the conversation.
  static Future<bool> isParticipant(int conversationId, String userId) async {
    try {
      final res = await _db
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      final ok = res != null;
      print('DEBUG: isParticipant conv=$conversationId user=$userId => $ok');
      return ok;
    } catch (e) {
      print('DEBUG: isParticipant error: $e');
      return false;
    }
  }
}
