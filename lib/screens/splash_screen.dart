import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/screens/employee_dashboard.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';

// --- JWT Debugging Snippet ---
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      print('Invalid token format');
      return null;
    }

    String payload = parts[1];
    int padLength = (4 - payload.length % 4) % 4;
    payload += '=' * padLength;
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');

    final decoded = utf8.decode(base64Url.decode(payload));
    final payloadMap = json.decode(decoded) as Map<String, dynamic>;
    return payloadMap;
  } catch (e) {
    print('Failed to decode JWT payload: $e');
    return null;
  }
}

void printTokenPayload(String token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) {
    print('No payload decoded');
    return;
  }
  print('JWT payload: $payload');

  final role = payload['role'] ?? payload['https://hasura.io/jwt/claims']?['x-hasura-role'] ?? payload['app_metadata']?['role'];
  print('Detected role claim: $role');
}
// --- End of Snippet ---

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
      Navigator.of(context).pushReplacementNamed('/start');
      return;
    }

    // ---
    // Print JWT payload for debugging
    printTokenPayload(session.accessToken);
    // ---

    try {
      final userId = session.user.id;
      final metaRole = (session.user.userMetadata?['role'] as String?)?.toLowerCase();
      if (metaRole != null && metaRole.isNotEmpty) {
        if (metaRole == 'manager') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
          return;
        }
        if (metaRole == 'employee') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const EmployeeDashboard()),
          );
          return;
        }
        if (metaRole == 'customer') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CustomerDashboard()),
          );
          return;
        }
      }

      final rawMgr = await supabase
          .from('managers')
          .select('id, auth_user_id, email')
          .eq('auth_user_id', userId)
          .maybeSingle();
      if (rawMgr != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
        return;
      }

      final rawEmp = await supabase
          .from('employees')
          .select('role, employee_id, first_name')
          .eq('auth_user_id', userId)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (rawEmp is Map) {
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
        final rawCust = await supabase
            .from('customers')
            .select('customer_id, email')
            .eq('auth_user_id', userId)
            .maybeSingle();

        if (rawCust != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CustomerDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacementNamed('/start');
        }
      }
    } catch (e) {
      print('Error during splash screen redirect: $e');
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
