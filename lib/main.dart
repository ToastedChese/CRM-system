import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load .env
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // DEBUG: print Supabase config (masked anon key) so we can verify the runtime values
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

  // ✅ Initialize SharedPreferences for theme service
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(prefs),
      child: const PowerLinkCRM(),
    ),
  );
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
          },
        );
      },
    );
  }
}
