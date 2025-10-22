
import 'package:flutter/material.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  /*
  // --- Backend Integration Placeholder ---
  // 
  // Future<void> _sendVerificationCode(String phoneNumber) async {
  //   // 1. Show a loading indicator to the user.
  //   //    e.g., setState(() => _isLoading = true));
  //
  //   try {
  //     // 2. Make an API call to your backend service.
  //     //    Your backend would then use a service like Twilio, Firebase Auth, etc.,
  //     //    to send an SMS with a verification code to the user's phone number.
  //     //
  //     //    Example API call:
  //     //    final response = await http.post(
  //     //      Uri.parse('https://your-api.com/send-verification-code'),
  //     //      body: {'phoneNumber': phoneNumber},
  //     //    );
  //
  //     // 3. Handle the response from your server.
  //     //    If the code was sent successfully, navigate to the OTP entry screen.
  //     //    if (response.statusCode == 200) {
  //     //      Navigator.of(context).push(
  //     //        MaterialPageRoute(
  //     //          builder: (context) => OTPScreen(phoneNumber: phoneNumber),
  //     //        ),
  //     //      );
  //     //    } else {
  //     //      // Handle server errors (e.g., show a snackbar).
  //     //    }
  //
  //   } catch (e) {
  //     // 4. Handle network errors or other exceptions.
  //     //    (e.g., show a snackbar with an error message).
  //   } finally {
  //     // 5. Hide the loading indicator.
  //     //    e.g., setState(() => _isLoading = false));
  //   }
  // }
  */

  void _onSendCodePressed() {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneNumberController.text;
      // --- Trigger the backend logic ---
      // Uncomment the line below when you're ready to integrate your backend.
      // _sendVerificationCode(phoneNumber);

      // For now, we'll just print to the console.
      // print('Sending verification code to: $phoneNumber');
      
      // You would typically navigate to an OTP screen here.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP functionality not implemented yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF182D53)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Enter Phone Number',
          style: TextStyle(
            color: Color(0xFF182D53),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Verify Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF182D53),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We will send you a one-time password to your phone number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF736A66),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +1 234 567 8900',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Basic validation for a phone number format
                    if (!RegExp(r'^\+?[0-9\s-]{10,}$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _onSendCodePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C7BED),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Send Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
