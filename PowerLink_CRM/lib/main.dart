import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/add_customer_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/help_chat_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(PowerLinkCRM());
}

class PowerLinkCRM extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerLink CRM',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/customers': (context) => CustomersScreen(),
        '/addCustomer': (context) => AddCustomerScreen(),
        '/visits': (context) => VisitsScreen(),
        '/helpChat': (context) => HelpChatScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
