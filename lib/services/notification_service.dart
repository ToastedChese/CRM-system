import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  static const _prefsKey = 'recent_notifications_v2'; // Key updated for new structure
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final StreamController<Map<String, dynamic>> _recentController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get recentNotificationStream => _recentController.stream;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings();

      await _plugin.initialize(
        InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        const channel = AndroidNotificationChannel(
          'messages_channel',
          'Messages',
          description: 'Notifications for incoming messages',
          importance: Importance.max,
        );
        await androidPlugin?.createNotificationChannel(channel);
      } catch (e) {
        print('DEBUG: failed to create Android notification channel: $e');
      }

      _initialized = true;
    } catch (e, st) {
      print('❌ NotificationService.init failed: $e');
      print(st);
      _initialized = false;
    }
  }

  Future<bool> _canNotify() async {
    try {
      final status = await Permission.notification.status;
      if (Platform.isAndroid) return true;
      return status.isGranted;
    } catch (_) {
      return Platform.isAndroid;
    }
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    if (!await _canNotify()) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications for incoming messages',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      print('❌ showNotification failed: $e');
    }
  }

  Future<void> addRecentNotification({required String title, required String body, DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_prefsKey) ?? [];

    final entryMap = {
      'title': title,
      'body': body,
      'ts': (at ?? DateTime.now()).toIso8601String(),
    };

    bool exists = list.any((s) {
      try {
        final existing = jsonDecode(s) as Map<String, dynamic>;
        return existing['title'] == title && existing['body'] == body;
      } catch (_) {
        return false;
      }
    });

    if (exists) {
      return;
    }

    final entry = jsonEncode(entryMap);

    final updated = [entry, ...list];
    if (updated.length > 10) {
      updated.removeRange(10, updated.length);
    }

    await prefs.setStringList(_prefsKey, updated);

    _recentController.add(entryMap);
  }

  Future<List<Map<String, dynamic>>> getRecentNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_prefsKey) ?? [];
    return list.map((s) {
      try {
        return Map<String, dynamic>.from(jsonDecode(s) as Map);
      } catch (_) {
        return {'title': 'Error', 'body': 'Could not decode notification.'};
      }
    }).toList();
  }

  // This method now explicitly sets the list to empty, which is more robust than remove().
  Future<void> clearRecentNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, []); // Explicitly set to an empty list.
    // Send a special event to force UI to clear its state.
    _recentController.add({'action': 'clear'});
  }

  void dispose() {
    _recentController.close();
  }
}
