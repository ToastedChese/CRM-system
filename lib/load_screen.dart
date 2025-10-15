import 'package:flutter/material.dart';
import 'sign_in.dart'; // Make sure this path is correct

class LoginSignUp extends StatefulWidget {
  const LoginSignUp({super.key});

  @override
  LoginSignUpState createState() => LoginSignUpState();
}

class LoginSignUpState extends State<LoginSignUp> {
  void navigateToSignIn() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignIn(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
              children: [
                // Top image
                Container(
                  margin: const EdgeInsets.only(top: 50, bottom: 20),
                  height: 300,
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/my7i1j9u_expires_30_days.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                // Main text
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: const Text(
                    "Experience Seamless CRM \n      and Data Anytime",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Buttons row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      // Login button
                      Expanded(
                        child: InkWell(
                          onTap: navigateToSignIn, // Navigate to SignIn
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF366EFA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Sign up button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            print('Sign Up Pressed');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0x66000000), width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFF353434),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Terms and Privacy Policy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: const [
                      Text(
                        "By signing up, you agree to our Terms and Condition.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Learn how we use your data in our Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
