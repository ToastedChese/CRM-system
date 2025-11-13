// TEST EDIT: single-line comment added by assistant to verify file-editing capability.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _termsAccepted = false;

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            '''
By using this application, you agree to the following terms and conditions:

1.  **Service Agreement:** You are granted a non-exclusive, non-transferable license to use this CRM application for your business purposes.

2.  **Data Privacy:** We are committed to protecting your data. We collect and store customer information, which may include names, contact details, and other relevant data, solely for the purpose of providing and improving our services. We will not share, sell, or disclose your data to any third parties without your explicit consent, unless required by law.

3.  **User Responsibilities:** You are responsible for maintaining the confidentiality of your account credentials. You agree not to misuse the application by uploading any illegal, harmful, or offensive content.

4.  **Limitation of Liability:** This application is provided "as is" without any warranties. We are not liable for any direct, indirect, or consequential damages arising from the use or inability to use this application.

5.  **Changes to Terms:** We reserve the right to modify these terms at any time. Your continued use of the application after any changes constitutes your acceptance of the new terms.

By clicking "Accept," you acknowledge that you have read, understood, and agree to be bound by these terms.
            ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _launchPrivacyPolicyURL() async {
    final Uri url = Uri.parse('https://sapower.co.za/privacy-policy');
    if (!await launchUrl(url)) {
      // Could not launch the URL
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 150,
                ),
                const SizedBox(height: 40),
                const Text(
                  "Welcome to PowerLink",
                  style: TextStyle(
                    color: Color(0xFF2C426A),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Boost your business connections effortlessly.",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                          children: <TextSpan>[
                            const TextSpan(text: 'I have read and agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsDialog,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _launchPrivacyPolicyURL,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_termsAccepted) {
                      Navigator.pushNamed(context, '/welcome');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please accept the terms and conditions to continue.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C426A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50), // Make button wider
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
