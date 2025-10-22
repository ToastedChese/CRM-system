import 'package:flutter/material.dart';
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
import 'package:powerlink_crm/screens/manager_dashboard.dart'; // Import the new manager dashboard

void main() {
  // Ensures that Flutter widgets are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
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
      // The SplashScreen handles initialization and then navigates.
      home: const SplashScreen(),
      // Define all the navigation routes for your app for clean navigation.
      routes: {
        // The new start screen, which serves as the onboarding/welcome page.
        '/start': (context) => const StartScreen(),
        // Public-facing screen with Login/Sign Up buttons.
        '/welcome': (context) => const WelcomeScreen(),
        // The main sign-in screen for users.
        '/login': (context) => const SignIn(),
        // The new placeholder screen for user registration.
        '/signup': (context) => const SignUp(),
        // The main dashboard shown after a successful login.
        '/dashboard': (context) => const DashboardScreen(),
        // Screen to view the list of all customers.
        '/customers': (context) => const CustomerDashboard(),
        // Manager Dashboard
        '/managerDashboard': (context) => const ManagerDashboard(),
        // Form to add a new customer to the database.
        '/addCustomer': (context) => const AddCustomerScreen(),
        // Screen to view and manage scheduled visits.
        '/visits': (context) => const VisitsScreen(),
        // In-app chat for help and support.
        '/helpChat': (context) => const HelpChatScreen(),
        // Screen for user settings and profile information.
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
