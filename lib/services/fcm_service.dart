import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  // Singleton pattern
  FcmService._privateConstructor();
  static final FcmService _instance = FcmService._privateConstructor();
  factory FcmService() => _instance;

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission from the user
    await _messaging.requestPermission();

    // Get the FCM token and save it to Supabase
    _messaging.getToken().then((token) {
      if (token != null) {
        print('FCM Token: $token'); // For debugging
        _saveTokenToSupabase(token);
      }
    });

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    bool savedAtLeastOnce = false;

    // Attempt to update the employees table
    try {
      final employeeRes = await Supabase.instance.client
          .from('employees')
          .update({'fcm_token': token})
          .eq('auth_user_id', userId)
          .select(); 

      if (employeeRes.isNotEmpty) {
        print('FCM token successfully saved to employees table.');
        savedAtLeastOnce = true;
      }
    } catch (e) {
      print('Error saving FCM token to employees table: $e');
    }

    // Attempt to update the managers table, regardless of employee result
    try {
      final managerRes = await Supabase.instance.client
          .from('managers')
          .update({'fcm_token': token})
          .eq('auth_user_id', userId)
          .select();
          
      if (managerRes.isNotEmpty) {
        print('FCM token successfully saved to managers table.');
        savedAtLeastOnce = true;
      }
    } catch (e) {
      print('Error saving FCM token to managers table: $e');
    }

    if (!savedAtLeastOnce) {
      print('FCM token not saved: User with auth_user_id=$userId not found in employees or managers tables.');
    }
  }
}
