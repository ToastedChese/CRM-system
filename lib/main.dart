import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:powerlink_crm/screens/add_customer_screen.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';
import 'package:powerlink_crm/screens/dashboard_screen.dart';
import 'package:powerlink_crm/screens/help_chat_screen.dart';
import 'package:powerlink_crm/screens/settings_screen.dart';
import 'package:powerlink_crm/screens/sign_in.dart';
import 'package:powerlink_crm/screens/sign_up.dart';
import 'package:powerlink_crm/screens/splash_screen.dart';
import 'package:powerlink_crm/screens/start_screen.dart';
import 'package:powerlink_crm/screens/visits_screen.dart';
import 'package:powerlink_crm/screens/welcome_screen.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load .env
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // ✅ Test connection
  final client = Supabase.instance.client;
  try {
    await client.from('customers').select('id').limit(1);
    print('✅ Supabase connected successfully.');
  } catch (e) {
    print('❌ Supabase connection failed: $e');
  }

  runApp(const PowerLinkCRM());
}

class PowerLinkCRM extends StatelessWidget {
  const PowerLinkCRM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerLink CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/start': (context) => const StartScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const SignIn(),
        '/signup': (context) => const SignUp(),
        '/dashboard': (context) => const DashboardScreen(),
        '/customers': (context) => const CustomerDashboard(),
        '/managerDashboard': (context) => const ManagerDashboard(),
        '/addCustomer': (context) => const AddCustomerScreen(),
        '/visits': (context) => const VisitsScreen(),
        '/helpChat': (context) => const HelpChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
