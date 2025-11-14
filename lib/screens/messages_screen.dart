import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../data/chat_service.dart';
import 'package:powerlink_crm/services/notification_service.dart';


class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  StreamSubscription<void>? _convosSub;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    // Initial load
    _load();
    // Listen for changes
    _convosSub = ChatService.listenConversations().listen((_) => _load());
    NotificationService().init();
  }

  @override
  void dispose() {
    _convosSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _conversations = await ChatService.myConversations();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _fmtTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${dt.month}/${dt.day} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Prefer scaffoldBackgroundColor so dark/light modes are respected
    final scaffoldBg = theme.scaffoldBackgroundColor;
    // use fixed mainBlue for AppBar/avatar to match brand, rest uses theme

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _createGroupFlow,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: _startDmFlow,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: _conversations.isEmpty
                  ? const Center(child: Text('No conversations yet'))
                  : ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _conversations[i];
                        final isGroup = (c['is_group'] as bool?) ?? false;

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: ChatService.participants(c['id'] as int),
                          builder: (ctx, snapParts) {
                            String titleText = 'Group';
                            String? avatarUrl;
                            if (isGroup) {
                              final t = (c['title'] as String?)?.trim();
                              titleText = (t?.isNotEmpty == true)
                                  ? t!
                                  : 'Group';
                            } else if (snapParts.hasData) {
                              final uid = sp.Supabase.instance.client.auth.currentUser?.id;
                              final others = snapParts.data!.where((m) => m['user_id'] != uid);
                              final other = others.isNotEmpty ? others.first : (snapParts.data!.isNotEmpty ? snapParts.data!.first : null);
                              if (other != null) {
                                titleText = (other['display_name'] ?? other['email'] ?? 'Direct Message').toString();
                                avatarUrl = (other['avatar_url'] as String?);
                              } else {
                                titleText = 'Direct Message';
                              }
                            }

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: ChatService.lastMessage(c['id'] as int),
                              builder: (ctx, snapLast) {
                                final subtitle = (snapLast.data?['body'] ?? '').toString();
                                final ts = (snapLast.data?['created_at'] ?? '').toString();

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: mainBlue,
                                    foregroundColor: Colors.white,
                                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                                    child: (avatarUrl?.isEmpty ?? true) ? const Icon(Icons.person, color: Colors.white) : null,
                                  ),
                                  title: Text(titleText, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    subtitle.isEmpty ? (isGroup ? 'Tap to view' : 'Start the conversation') : subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: ts.isEmpty ? null : Text(_fmtTime(ts), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()))),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ConversationScreen(
                                          conversationId: c['id'] as int,
                                        ),
                                      ),
                                    );
                                    // After returning from the conversation, refresh the list.
                                    _load();
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }

  // ─────────────── Create DM / Group flows ───────────────

  Future<void> _startDmFlow() async {
    final picked = await _pickUsers(single: true);
    if (picked.isEmpty) return;
    try {
      final row = await ChatService.getOrCreateDm(otherUserId: picked.first);
      if (!mounted) return;
      // Navigate and then refresh when the user comes back.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversationId: row['id'] as int),
        ),
      );
      _load();
    } catch (e) {
      _snack('DM failed: $e');
    }
  }

  Future<void> _createGroupFlow() async {
    final picked = await _pickUsers(single: false);
    if (picked.isEmpty) return;

    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Group name'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'e.g. Sales Team')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final row = await ChatService.createGroup(title: titleCtrl.text.trim(), participantUserIds: picked);
      if (!mounted) return;
      // Navigate and then refresh when the user comes back.
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationScreen(conversationId: row['id'] as int)),
      );
      _load();
    } catch (e) {
      _snack('Create group failed: $e');
    }
  }

  // ─────────────── People picker ───────────────

  Timer? _debouncer;
  Future<List<String>> _pickUsers({required bool single}) async {
    final selected = <String>{};
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        Future<void> doSearch() async {
          final q = searchCtrl.text.trim();
          results = await ChatService.searchDirectory(q);
          if (mounted) setState(() {});
        }

        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  onChanged: (_) {
                    _debouncer?.cancel();
                    _debouncer = Timer(const Duration(milliseconds: 250), () async {
                      await doSearch();
                      setLocal(() {});
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Search people', prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Type a name or email to search', style: TextStyle(color: Colors.grey[600])),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        final id = (r['user_id'] ?? '').toString();
                        final dn = (r['display_name'] ?? r['email'] ?? 'Unknown').toString();
                        final email = (r['email'] ?? '').toString();
                        final avatarUrl = (r['avatar_url'] ?? '').toString();
                        final checked = selected.contains(id);

                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) => setLocal(() {
                            if (single) selected.clear();
                            if (v == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                          secondary: CircleAvatar(
                            backgroundColor: const Color.fromARGB(38, 24, 45, 83),
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(dn, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Select'),
                    onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return selected.toList();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});
  final int conversationId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _conversation;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _messages = [];

  final _sendCtrl = TextEditingController();
  sp.RealtimeChannel? _channel;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _prime();
    NotificationService().init();
  }

  @override
  void dispose() {
    _sendCtrl.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _prime() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conv = await ChatService.conversation(widget.conversationId);
      final parts = await ChatService.participants(widget.conversationId);
      final msgs = await ChatService.messages(widget.conversationId, limit: 200);

      _conversation = conv;
      _members = parts;
      _messages = msgs;

      _channel = ChatService.subscribeMessages(
        conversationId: widget.conversationId,
        onInsert: (row) async {
          setState(() => _messages.add(row));

          try {
            await Future.delayed(const Duration(milliseconds: 50));
            if (_scrollController.hasClients) {
              _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            }
          } catch (_) {}

          final me = sp.Supabase.instance.client.auth.currentUser?.id ?? '';
          final senderId = (row['sender_id'] ?? '').toString();
          if (senderId != me) {
            final isGroup = (_conversation?['is_group'] as bool?) ?? false;
            String title;
            if (isGroup) {
              title = (_conversation?['title'] as String?)?.trim() ?? 'Group Message';
              if (title.isEmpty) title = 'Group Message';
            } else {
              final senderName = _members.firstWhere((m) => (m['user_id'] ?? '') == senderId, orElse: () => {'display_name': 'Someone'})['display_name'] ?? 'Someone';
              title = senderName.toString();
            }

            final body = (row['body'] ?? '').toString();
            NotificationService().showNotification(id: DateTime.now().millisecondsSinceEpoch.remainder(100000), title: title, body: body);
            NotificationService().addRecentNotification(
              title: title,
              body: body,
              at: DateTime.tryParse(row['created_at'] as String? ?? ''),
            );
          }
        },
      );
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _title() {
    if (_conversation == null) return 'Conversation';
    final isGroup = (_conversation!['is_group'] as bool?) ?? false;
    if (isGroup) {
      final t = (_conversation!['title'] as String?)?.trim();
      return (t?.isNotEmpty == true) ? t! : 'Group';
    }
    final uid = sp.Supabase.instance.client.auth.currentUser?.id;
    final other = _members.firstWhere((m) => (m['user_id'] as String?) != uid, orElse: () => _members.isNotEmpty ? _members.first : {});
    return (other['display_name'] ?? other['email'] ?? 'Direct Message').toString();
  }

  @override
  Widget build(BuildContext context) {
    final title = _title();
    final me = sp.Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showConversationInfo(isGroup: (_conversation?['is_group'] as bool?) ?? false)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final mine = (m['sender_id'] ?? '') == me;
                      final body = (m['body'] ?? '').toString();
                      final time = (m['created_at'] ?? '').toString();

                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(color: mine ? mainBlue : Colors.grey[200], borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(body, style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                              const SizedBox(height: 4),
                              Text(_fmtTime(time), style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.black45)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sendCtrl,
                            minLines: 1,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Type a message…',
                              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: mainBlue), borderRadius: BorderRadius.circular(24)),
                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: mainBlue, width: 2), borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: mainBlue, foregroundColor: Colors.white),
                          onPressed: _send,
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _fmtTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${dt.month}/${dt.day} $hh:$mm';
  }

  Future<void> _send() async {
    final text = _sendCtrl.text.trim();
    if (text.isEmpty) return;
    _sendCtrl.clear();
    try {
      final sent = await ChatService.sendMessage(conversationId: widget.conversationId, body: text);

      setState(() => _messages.add(sent));
      await Future.delayed(const Duration(milliseconds: 80));
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 100);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  Future<void> _showConversationInfo({required bool isGroup}) async {
    final nameCtrl = TextEditingController(text: _title());

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: mainBlue),
                  const SizedBox(width: 8),
                  Text('Conversation info', style: Theme.of(ctx).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              if (isGroup) ...[
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Group name', prefixIcon: Icon(Icons.edit))),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save name'),
                    style: FilledButton.styleFrom(backgroundColor: mainBlue),
                    onPressed: () async {
                      try {
                        await ChatService.updateConversationTitle(conversationId: widget.conversationId, title: nameCtrl.text);
                        if (mounted) {
                          Navigator.pop(ctx);
                          await _prime();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text('Participants (${_members.length})', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = _members[i];
                    final dn = (m['display_name'] ?? m['email'] ?? 'Unknown').toString();
                    final email = (m['email'] ?? '').toString();
                    final avatar = (m['avatar_url'] ?? '').toString();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color.fromARGB(26, 24, 45, 83),
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        child: avatar.isEmpty ? const Icon(Icons.person, color: mainBlue) : null,
                      ),
                      title: Text(dn),
                      subtitle: Text(email),
                    );
                  },
                ),
              ),
              if (isGroup) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add participants'),
                  style: FilledButton.styleFrom(backgroundColor: mainBlue),
                  onPressed: _showAddMembers,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddMembers() async {
    final picked = await (context.findAncestorStateOfType<_MessagesScreenState>()?._pickUsers(single: false) ?? Future.value(<String>[]));
    if (picked.isEmpty) return;
    try {
      await ChatService.addParticipants(conversationId: widget.conversationId, userIds: picked);
      await _prime();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }
}
