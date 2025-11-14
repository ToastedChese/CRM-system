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

  @override
  void initState() {
    super.initState();
    _load();
    // Listen for live updates so the UI refreshes when notifications arrive
    NotificationService().recentNotificationStream.listen((_) async {
      await _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NotificationService().getRecentNotifications();
    setState(() {
      _notifications = list;
      _loading = false;
    });
  }

  String _fmtTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
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
            onPressed: _notifications.isEmpty
                ? null
                : () async {
                    await NotificationService().clearRecentNotifications();
                    await _load();
                  },
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
                    return ListTile(
                      leading: const Icon(Icons.notifications_none_outlined),
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (body.isNotEmpty) Text(body),
                          if (ts.isNotEmpty) Text(_fmtTime(ts), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
