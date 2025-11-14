import 'dart:async';
import 'package:flutter/material.dart';
import 'package:powerlink_crm/services/notification_service.dart';

class RecentNotificationsScreen extends StatefulWidget {
  const RecentNotificationsScreen({super.key});

  @override
  State<RecentNotificationsScreen> createState() => _RecentNotificationsScreenState();
}

class _RecentNotificationsScreenState extends State<RecentNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadInitialNotifications();
    _listenForLiveUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Prevent memory leaks
    super.dispose();
  }

  // Load the initial list from storage only once.
  Future<void> _loadInitialNotifications() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await NotificationService().getRecentNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = list;
      _loading = false;
    });
  }

  // Listen to the stream for live updates to the in-memory list.
  void _listenForLiveUpdates() {
    _subscription = NotificationService().recentNotificationStream.listen((event) {
      if (!mounted) return;

      // Check for the special 'clear' action from the service
      if (event.containsKey('action') && event['action'] == 'clear') {
        setState(() {
          _notifications.clear(); // Clear the in-memory list directly
        });
        return;
      }

      // Otherwise, add the new notification to the top of the in-memory list.
      setState(() {
        _notifications.insert(0, event);
      });
    });
  }

  // The clear button now only needs to call the service.
  // The stream listener will handle updating the UI.
  Future<void> _clearAll() async {
    await NotificationService().clearRecentNotifications();
  }

  String _fmtTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all notifications',
            onPressed: _notifications.isEmpty ? null : _clearAll,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'You have no recent notifications.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final title = (n['title'] ?? 'Notification').toString();
                    final body = (n['body'] ?? '').toString();
                    final ts = (n['ts'] ?? '').toString();

                    // Don't display the internal 'clear' event in the list
                    if (title == 'cleared') return const SizedBox.shrink();

                    return ListTile(
                      leading: const Icon(Icons.notifications_none_outlined),
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (body.isNotEmpty) Text(body),
                          if (ts.isNotEmpty)
                            Text(_fmtTime(ts), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
