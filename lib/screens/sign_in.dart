import 'package:flutter/material.dart';
import 'package:powerlink_crm/services/authentication.dart';
import 'package:powerlink_crm/screens/employee_dashboard.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart'; // Added by Gemini
import 'forgotten_password_screen.dart';
import 'package:powerlink_crm/models/employee.dart';
import 'package:powerlink_crm/models/customer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final emailTrim = emailController.text.trim();
      final emailLower = emailTrim.toLowerCase();

      // === 1) Auth via AuthService (centralized, diagnostic-rich) ===
      final pwdLen = passwordController.text.length;
      print('DEBUG: signInForm -> calling AuthService.signIn email="$emailLower" pwdLen=$pwdLen');

      final result = await _authService.signIn(emailTrim, passwordController.text);
      print('DEBUG: signInForm -> AuthService.signIn returned: $result');

      if (result == null) {
        // sign-in failed; AuthService already printed diagnostics, show simple UI feedback
        _showSnack('Sign-in failed. Check your email & password.');
        return;
      }

      // If AuthService returned an Employee instance, decide between Manager/Employee
      if (result is Employee) {
        final roleLower = result.role.toLowerCase();
        if (roleLower == 'manager') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ManagerDashboard()),
            (route) => false,
          );
          return;
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
            (route) => false,
          );
          return;
        }
      }

      // Customer
      if (result is Customer) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
          (route) => false,
        );
        return;
      }

      // === 4) Unknown ===
      _showSnack('Unknown user type. Ask support to check your profile.');
    } catch (e) {
      if (e is AuthException) {
        _showSnack(e.message);
      } else if (e is PostgrestException) {
        _showSnack('Database error: ${e.message}');
      } else {
        _showSnack('Sign-in error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                const SizedBox(height: 50),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/welcome_illustration.png',
                    height: 200, // Adjust height as needed
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Sign In To PowerLink",
                  style: textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 22),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 23),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgottenPassword()),
                    );
                  },
                  child: const Text("Forgot Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// Added single-line comment for CODE-COMPLETION-TEST
