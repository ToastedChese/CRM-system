import 'package:flutter/material.dart';
import 'authentication.dart';

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

    final employee = await _authService.signInEmployee(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (employee != null) {
      Navigator.pushReplacementNamed(context, '/home'); //need changing depending on screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFFFFFEF9),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicHeight(
                          child: Container(
                            margin: const EdgeInsets.only(top: 32),
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 235),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      IntrinsicHeight(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(30),
                                            color: const Color(0xFFFFFFFF),
                                          ),
                                          padding: const EdgeInsets.only(
                                              top: 101, bottom: 7, left: 28, right: 28),
                                          width: double.infinity,
                                          child: Column(
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 32, left: 21, right: 21),
                                                width: double.infinity,
                                                child: const Text(
                                                  "Sign In To PowerLink",
                                                  style: TextStyle(
                                                    color: Color(0xFF182D53),
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              // Email Field
                                              Container(
                                                margin: const EdgeInsets.only(bottom: 8, right: 238),
                                                child: const Text(
                                                  "Email Address",
                                                  style: TextStyle(
                                                    color: Color(0xFF4E3321),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IntrinsicHeight(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(0xFFB59F5E),
                                                      width: 1,
                                                    ),
                                                    borderRadius: BorderRadius.circular(1154),
                                                    color: const Color(0xFFFFFFFF),
                                                  ),
                                                  padding: const EdgeInsets.all(14),
                                                  margin: const EdgeInsets.only(bottom: 22),
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 7),
                                                        width: 22,
                                                        height: 22,
                                                        child: Image.network(
                                                          "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/sami1sz5_expires_30_days.png",
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          controller: emailController,
                                                          decoration: const InputDecoration(
                                                            hintText: "Enter your email",
                                                            border: InputBorder.none,
                                                          ),
                                                          keyboardType: TextInputType.emailAddress,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Password Field
                                              Container(
                                                margin: const EdgeInsets.only(bottom: 7, right: 267),
                                                child: const Text(
                                                  "Password",
                                                  style: TextStyle(
                                                    color: Color(0xFF4E3321),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IntrinsicHeight(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(1154),
                                                    color: const Color(0xFFFFFFFF),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  margin: const EdgeInsets.only(bottom: 23),
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets.only(left: 14, right: 7),
                                                        width: 22,
                                                        height: 22,
                                                        child: Image.network(
                                                          "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/s4nh2qh8_expires_30_days.png",
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          controller: passwordController,
                                                          obscureText: _obscurePassword,
                                                          decoration: const InputDecoration(
                                                            hintText: "Enter your password",
                                                            border: InputBorder.none,
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
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
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Sign In Button
                                              _isLoading
                                                  ? const Center(child: CircularProgressIndicator())
                                                  : InkWell(
                                                      onTap: _signIn,
                                                      child: IntrinsicHeight(
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(935),
                                                            color: const Color(0xFF2C426A),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          width: double.infinity,
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                margin: const EdgeInsets.only(right: 14),
                                                                child: const Text(
                                                                  "Sign In",
                                                                  style: TextStyle(
                                                                    color: Color(0xFFFFFFFF),
                                                                    fontSize: 18,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 22,
                                                                height: 22,
                                                                child: Image.network(
                                                                  "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/1p64j3on_expires_30_days.png",
                                                                  fit: BoxFit.fill,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(height: 10),
                                              // Sign Up Link
                                              GestureDetector(
                                                onTap: () => Navigator.pushNamed(context, '/sign_up'),
                                                child: const Text(
                                                  "Don’t have an account? Sign Up.",
                                                  style: TextStyle(
                                                    color: Color(0xFF736A66),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Forgot Password
                                              GestureDetector(
                                                onTap: () {
                                                  // Add forgot password logic here
                                                  print("Forgot Password tapped");
                                                },
                                                child: const Text(
                                                  "Forgot Password",
                                                  style: TextStyle(
                                                    color: Color(0xFF3C7BED),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(20),
                                                  color: const Color(0xFF9E9898),
                                                ),
                                                width: 105,
                                                height: 4,
                                                child: const SizedBox(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 6,
                                  right: 6,
                                  height: 288,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    height: 288,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.network(
                                        "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/iDdSNijdGI/h6ef9umf_expires_30_days.png",
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}