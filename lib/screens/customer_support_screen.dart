import 'package:flutter/material.dart';

// A screen where customers can submit support requests.
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final bool _isSubmitting = false;

  /*
  // --- Database Integration Placeholder ---
  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if the form is invalid
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement database call to create a new support ticket.
    // try {
    //   final userId = FirebaseAuth.instance.currentUser?.uid;
    //   final userEmail = FirebaseAuth.instance.currentUser?.email;
    //
    //   if (userId == null) throw Exception("User not logged in");
    //
    //   await FirebaseFirestore.instance.collection('supportTickets').add({
    //     'customerId': userId,
    //     'customerEmail': userEmail,
    //     'subject': _subjectController.text,
    //     'message': _messageController.text,
    //     'status': 'Open', // e.g., Open, In Progress, Closed
    //     'createdAt': FieldValue.serverTimestamp(),
    //   });
    //
    //   // Show success message and clear the form
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Support request submitted successfully!')),
    //   );
    //   _formKey.currentState!.reset();
    //   _subjectController.clear();
    //   _messageController.clear();
    //
    // } catch (e) {
    //   // Show error message
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to submit request: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isSubmitting = false;
    //   });
    // }
  }
  */

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF182D53),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill out the form below and a support agent will get back to you.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () {}, // Disabled when submitting, replace {} with _submitSupportRequest
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF182D53),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
