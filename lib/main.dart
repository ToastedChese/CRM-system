import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

import 'package:powerlink_crm/screens/add_customer_screen.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';
import 'package:powerlink_crm/screens/help_chat_screen.dart';
import 'package:powerlink_crm/screens/settings_screen.dart';
import 'package:powerlink_crm/screens/sign_in.dart';
import 'package:powerlink_crm/screens/sign_up.dart';
import 'package:powerlink_crm/screens/splash_screen.dart';
import 'package:powerlink_crm/screens/start_screen.dart';
import 'package:powerlink_crm/screens/visits_screen.dart';
import 'package:powerlink_crm/screens/welcome_screen.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart';
import 'package:powerlink_crm/services/theme_service.dart';
import 'package:powerlink_crm/services/notification_service.dart';
import 'package:powerlink_crm/services/fcm_service.dart'; // Import the new service
import 'package:powerlink_crm/data/_global_subscriptions.dart';
import 'package:powerlink_crm/data/chat_service.dart';

// New Screens from Tameron's branch
import 'package:powerlink_crm/screens/create_task_screen.dart';
import 'package:powerlink_crm/screens/customer_rate_company_screen.dart';
import 'package:powerlink_crm/screens/gamification.dart';
import 'package:powerlink_crm/screens/meetings_screen.dart';
import 'package:powerlink_crm/screens/project_create_screen.dart';
import 'package:powerlink_crm/screens/tasks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('DEBUG_STARTUP: before dotenv.load');
  // ✅ Load .env
  await dotenv.load(fileName: ".env");
  print('DEBUG_STARTUP: after dotenv.load');

  print('DEBUG_STARTUP: before Firebase.initializeApp');
  // ✅ Initialize Firebase
  await Firebase.initializeApp();
  print('DEBUG_STARTUP: after Firebase.initializeApp');

  print('DEBUG_STARTUP: before Supabase.initialize');
  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  print('DEBUG_STARTUP: after Supabase.initialize');

  print('DEBUG: Supabase config (masked anon key) so we can verify the runtime values');
  try {
    final supUrl = dotenv.env['SUPABASE_URL'] ?? '<missing>';
    final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '<missing>';
    String mask(String s) {
      if (s == '<missing>') return s;
      if (s.length <= 8) return '****';
      return s.substring(0, 4) + '...' + s.substring(s.length - 4);
    }
    print('DEBUG: Supabase initialize called with url=$supUrl');
    print('DEBUG: Supabase anonKey=${mask(anon)}');
  } catch (e) {
    print('DEBUG: Failed to print Supabase .env values: $e');
  }

  print('DEBUG_STARTUP: before SharedPreferences.getInstance');
  // ✅ Initialize SharedPreferences for theme service
  final prefs = await SharedPreferences.getInstance();
  print('DEBUG_STARTUP: after SharedPreferences.getInstance');

  print('DEBUG_STARTUP: before runApp');
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(prefs),
      child: const PowerLinkCRM(),
    ),
  );
  print('DEBUG_STARTUP: after runApp');

  // Initialize services after app start so they do not block splash
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    print('DEBUG_STARTUP: postFrameCallback - init NotificationService');
    await NotificationService().init();

    print('DEBUG_STARTUP: postFrameCallback - init FcmService');
    await FcmService().init(); // Initialize FCM service

    // Also listen for auth state changes to (re)subscribe after sign-in
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;
        print('DEBUG: auth state change event=$event');
        if (session != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession)) {
          final uid = session.user.id;
          print('DEBUG: auth state change - user signed in uid=$uid');

          // Sync notifications for offline messages.
          ChatService.createNotificationsForOfflineMessages();

          // Ensure we have a subscription for this new user
          GlobalSubscriptions.subscribeAllMessages((row) async {
            try {
              final convId = (row['conversation_id'] ?? 0) as int;
              final senderId = (row['sender_id'] ?? '').toString();
              if (senderId == uid) return;
              final isPart = await ChatService.isParticipant(convId, uid);
              if (!isPart) return;
              final body = (row['body'] ?? '').toString();

              // Get conversation details to determine if it's a group chat
              final conv = await ChatService.conversation(convId);
              final isGroup = (conv['is_group'] as bool?) ?? false;

              String title;
              if (isGroup) {
                title = (conv['title'] as String?)?.trim() ?? 'Group Message';
                if (title.isEmpty) title = 'Group Message';
              } else {
                final parts = await ChatService.participants(convId);
                final other = parts.firstWhere(
                    (m) => (m['user_id'] as String?) == senderId,
                    orElse: () => parts.isNotEmpty ? parts.first : {});
                title = (other['display_name'] ?? other['email'] ?? 'Message').toString();
              }

              NotificationService().showNotification(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                title: title,
                body: body,
              );
              // Pass the original message timestamp to the notification service
              NotificationService().addRecentNotification(
                title: title,
                body: body,
                at: DateTime.tryParse(row['created_at'] as String? ?? ''),
              );
            } catch (e) {
              print('DEBUG: auth-listener global message handler error: $e');
            }
          });
        }
      });
    } catch (e) {
      print('DEBUG: failed to attach auth state listener: $e');
    }

    // Start global poller as a fallback in case realtime doesn't deliver
    try {
      _GlobalPoller.start();
    } catch (e) {
      print('DEBUG: failed to start GlobalPoller: $e');
    }
  });
}

// Global in-memory state for polling fallback
class _GlobalPoller {
  static Timer? _timer;
  static final Map<int, int> _lastMessageIdByConv = {};

  static void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final me = Supabase.instance.client.auth.currentUser?.id;
        if (me == null) return;
        final convs = await ChatService.myConversations();
        for (final c in convs) {
          final convId = (c['id'] as int);
          final last = await ChatService.lastMessage(convId);
          if (last == null) continue;
          final lastId = (last['id'] is int) ? last['id'] as int : int.tryParse(last['id'].toString()) ?? 0;
          final prev = _lastMessageIdByConv[convId] ?? 0;
          if (lastId > prev) {
            _lastMessageIdByConv[convId] = lastId;
            final senderId = (last['sender_id'] ?? '').toString();
            if (senderId != me) {
              final isGroup = (c['is_group'] as bool?) ?? false;
              String title;
              if (isGroup) {
                title = (c['title'] as String?)?.trim() ?? 'Group Message';
                if (title.isEmpty) title = 'Group Message';
              } else {
                final parts = await ChatService.participants(convId);
                final other = parts.firstWhere((m) => (m['user_id'] as String?) == senderId, orElse: () => parts.isNotEmpty ? parts.first : {});
                title = (other['display_name'] ?? other['email'] ?? 'Message').toString();
              }
              final body = (last['body'] ?? '').toString();
              print('DEBUG: GlobalPoller detected new message conv=$convId id=$lastId');
              // DO NOT re-show notifications for old messages, only add to recent list.
              NotificationService().addRecentNotification(
                title: title,
                body: body,
                at: DateTime.tryParse(last['created_at'] as String? ?? ''),
              );
            }
          }
        }
      } catch (e) {
        print('DEBUG: GlobalPoller error: $e');
      }
    });
    print('DEBUG: GlobalPoller started');
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _lastMessageIdByConv.clear();
    print('DEBUG: GlobalPoller stopped');
  }
}

class PowerLinkCRM extends StatelessWidget {
  const PowerLinkCRM({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF182D53);

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'PowerLink CRM',
          debugShowCheckedModeBanner: false,

          // Connect theme settings to the ThemeService
          themeMode: themeService.themeMode,

          // Define the light theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: Colors.grey[100],
            cardColor: Colors.white,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey[600],
            ),
             outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor, 
                side: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
             elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Define the dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey[400],
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white, 
                side: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          home: const SplashScreen(),
          routes: {
            '/start': (context) => const StartScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const SignIn(),
            '/signup': (context) => const SignUp(),
            '/customers': (context) => const CustomerDashboard(),
            '/managerDashboard': (context) => const ManagerDashboard(),
            '/addCustomer': (context) => const AddCustomerScreen(),
            '/visits': (context) => const VisitsScreen(),
            '/helpChat': (context) => const HelpChatScreen(),
            '/settings': (context) => const SettingsScreen(),
            // Routes for new screens
            '/createTask': (context) => const CreateTaskScreen(employeeId: null), // Placeholder employeeId
            '/rateCompany': (context) => const CustomerRateCompanyScreen(),
            '/gamification': (context) => const GamificationScreen(),
            '/meetings': (context) => const MeetingsScreen(),
            '/createProject': (context) => const ProjectCreateScreen(),
            '/tasks': (context) => const TasksScreen(),
          },
        );
      },
    );
  }
}
