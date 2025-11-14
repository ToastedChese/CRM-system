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

  static const _prefsKey = 'recent_notifications_v1';
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final StreamController<Map<String, dynamic>> _recentController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get recentNotificationStream => _recentController.stream;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Use non-const initialization to avoid potential platform edge cases
      final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings();

      await _plugin.initialize(
        InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      // Create Android notification channel for API 26+
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        const channel = AndroidNotificationChannel(
          'messages_channel',
          'Messages',
          description: 'Notifications for incoming messages',
          importance: Importance.max,
        );
        await androidPlugin?.createNotificationChannel(channel);
        print('DEBUG: Android notification channel created');
      } catch (e) {
        print('DEBUG: failed to create Android notification channel: $e');
      }

      _initialized = true;
      print('DEBUG: NotificationService initialized');
    } catch (e, st) {
      // Log and don't rethrow so startup won't be blocked by notification init errors
      print('❌ NotificationService.init failed: $e');
      print(st);
      _initialized = false;
    }
  }

  Future<bool> _canNotify() async {
    try {
      final status = await Permission.notification.status;
      print('DEBUG: notification permission status=$status');
      // On Android, prior to API 33 notifications don't require runtime permission
      // and some devices/reports may return unexpected values. Allow Android by default
      // and rely on the plugin/system to handle delivery.
      if (Platform.isAndroid) return true;
      return status.isGranted;
    } catch (_) {
      // If permission check fails, allow on Android, otherwise deny.
      try {
        if (Platform.isAndroid) return true;
      } catch (_) {}
      return false;
    }
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    final allowed = await _canNotify();
    if (!allowed) {
      print('DEBUG: showNotification skipped - permission not granted');
      return;
    }

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
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
      print('DEBUG: showNotification displayed id=$id title=$title');
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
    final entry = jsonEncode(entryMap);

    // Prepend and keep max 10
    final updated = [entry, ...list];
    if (updated.length > 10) updated.removeRange(10, updated.length);

    await prefs.setStringList(_prefsKey, updated);
    print('DEBUG: addRecentNotification saved title=$title');

    // Broadcast to listeners
    try {
      _recentController.add(entryMap);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getRecentNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_prefsKey) ?? [];
    return list.map((s) {
      try {
        return Map<String, dynamic>.from(jsonDecode(s) as Map);
      } catch (_) {
        return {
          'title': 'Notification',
          'body': s,
          'ts': DateTime.now().toIso8601String(),
        };
      }
    }).toList();
  }

  Future<void> clearRecentNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    try {
      _recentController.add({'title': 'cleared', 'body': ''});
    } catch (_) {}
  }

  void dispose() {
    _recentController.close();
  }
}
