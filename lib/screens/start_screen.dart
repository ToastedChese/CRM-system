import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services in the background.
      await dotenv.load(fileName: ".env");
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      // Wait for a short period to ensure the splash screen is visible.
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      // Navigate to the new OnboardingScreen.
      Navigator.pushReplacementNamed(context, '/onboarding');

    } catch (e) {
      print('❌ Error during initialization: $e');
      // In case of an error, still attempt to navigate after a delay.
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The UI is now just the centered logo, which serves as the splash screen.
    return const Scaffold(
      backgroundColor: Colors.white, // Match the logo's background
      body: Center(
        child: Image(image: AssetImage('assets/images/splash_logo.png')),
      ),
    );
  }
}
