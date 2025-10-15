import 'package:flutter/material.dart';
import 'load_screen.dart'; // Import your LoginSignUp screen

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // center vertically
                crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
                children: [
                  // Logo
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 73,
                    height: 73,
                    child: Image.network(
                      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/1m2etm2q_expires_30_days.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Title
                  const Text(
                    "Welcome to the ultimate CRM System",
                    style: TextStyle(
                      color: Color(0xFF182D53),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  const Text(
                    "Manage your clients, tasks, and business connections effortlessly — all in one powerful platform.",
                    style: TextStyle(
                      color: Color(0xFF736A66),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Illustration image
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    height: 300,
                    width: 300,
                    child: Image.network(
                      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/qdnp3tdr_expires_30_days.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Get Started button
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                          const LoginSignUp(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C426A),
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Get Started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 15),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.network(
                              "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/x82uc0rg_expires_30_days.png",
                              fit: BoxFit.fill,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Already have an account link
                  TextButton(
                    onPressed: () {
                      print('Sign In Pressed');
                    },
                    child: const Text(
                      "Already have an account? Sign In.",
                      style: TextStyle(
                        color: Color(0xFF736A66),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
