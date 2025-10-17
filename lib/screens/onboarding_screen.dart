import 'package:flutter/material.dart';

// This will be the welcome screen from the Figma illustration Carla provided us.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TODO: Add the main app logo image here.
            // Example: Image.asset('assets/images/app_logo.png'),
            const SizedBox(height: 20),

            const Text(
              'Placeholder for Onboarding Screen Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // TODO: Add the main illustration image here.
            // Example: Image.asset('assets/images/onboarding_illustration.png'),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // Navigate to the Welcome Screen (Login/Sign Up choices)
                Navigator.pushNamed(context, '/welcome');
              },
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 20),

            // TODO: Add the "Already have an account? Sign In" text here.
            // This should be a RichText widget to make 'Sign In' tappable.
            // It should navigate to the '/login' route.

          ],
        ),
      ),
    );
  }
}
