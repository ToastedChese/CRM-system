import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:powerlink_crm/screens/recent_notifications_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _areNotificationsEnabled = false; // Default to off

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  // Check the current permission status on screen load
  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      setState(() {
        _areNotificationsEnabled = true;
      });
    }
  }

  // Request notification permission and update the toggle
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();

    setState(() {
      _areNotificationsEnabled = status.isGranted;
    });

    if (status.isPermanentlyDenied) {
      // The user has permanently denied the permission. 
      // Open app settings to let them enable it manually.
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Notification permissions have been permanently denied. Please go to your app settings to enable them.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts and updates on your device'),
            value: _areNotificationsEnabled,
            onChanged: (bool value) {
              if (value) {
                // If turning on, request permission
                _requestNotificationPermission();
              } else {
                // If turning off, simply update the state
                setState(() {
                  _areNotificationsEnabled = false;
                });
              }
            },
            secondary: _areNotificationsEnabled
                ? const Icon(Icons.notifications_active)
                : const Icon(Icons.notifications_off_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Recent Notifications'),
            subtitle: const Text('View your notification history'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecentNotificationsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
