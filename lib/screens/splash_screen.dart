import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/screens/employee_dashboard.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      // No active session, go to the start screen.
      Navigator.of(context).pushReplacementNamed('/start');
      return;
    }

    try {
      // Session exists, so we have a user ID.
      final userId = session.user.id;

      final rawEmp = await supabase
          .from('employees')
          .select('role, employee_id, first_name')
          .eq('auth_user_id', userId)
          .limit(1)
          .maybeSingle();

      // If the widget got disposed in the meantime, stop.
      if (!mounted) return;

      if (rawEmp is Map) {
        // Directly use the returned map for role checking.
        final map = Map<String, dynamic>.from(rawEmp as Map);
        final role = (map['role'] as String?)?.toLowerCase();
        if (role == 'manager') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const EmployeeDashboard()),
          );
        }
      } else {
        // No employee record found; route to customer dashboard.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CustomerDashboard()),
        );
      }
    } catch (e) {
      print('Error during splash screen redirect: $e');
      // On any error, fall back to the start screen for safety.
      Navigator.of(context).pushReplacementNamed('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(image: AssetImage('assets/images/splash_logo.png')),
      ),
    );
  }
}
