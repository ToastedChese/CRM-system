import 'package:supabase_flutter/supabase_flutter.dart' as sp;

class GlobalSubscriptions {
  static final List<sp.RealtimeChannel> _channels = [];
  static bool _subscribed = false;

  static void subscribeAllMessages(void Function(Map<String, dynamic>) onInsert) {
    if (_subscribed) {
      print('DEBUG: GlobalSubscriptions already subscribed, skipping');
      return;
    }
    final channel = sp.Supabase.instance.client.channel('messages_global');
    channel.onPostgresChanges(
      event: sp.PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final r = Map<String, dynamic>.from(payload.newRecord);
        print('DEBUG: GlobalSubscriptions received row: $r');
        onInsert(r);
      },
    );
    channel.subscribe();
    _channels.add(channel);
    _subscribed = true;
    print('DEBUG: GlobalSubscriptions subscribed');
  }

  static void clear() {
    for (final c in _channels) {
      try {
        c.unsubscribe();
      } catch (_) {}
    }
    _channels.clear();
    _subscribed = false;
    print('DEBUG: GlobalSubscriptions cleared');
  }
}
