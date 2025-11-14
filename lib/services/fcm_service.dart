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
        _saveTokenToSupabase(token);
      }
    });

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Try to update the token in the 'employees' table
      final employeeRes = await Supabase.instance.client
          .from('employees')
          .update({'fcm_token': token})
          .eq('id', userId)
          .maybeSingle();

      if (employeeRes != null) {
        print('FCM token saved to employees table');
        return; // Token was saved, so we are done
      }

      // If the user wasn't in the employees table, try the 'managers' table
      final managerRes = await Supabase.instance.client
          .from('managers')
          .update({'fcm_token': token})
          .eq('id', userId)
          .maybeSingle();
          
      if (managerRes != null) {
        print('FCM token saved to managers table');
        return;
      }

      print('FCM token not saved: User not found in employees or managers tables.');

    } catch (e) {
      print('Error saving FCM token to Supabase: $e');
    }
  }
}
