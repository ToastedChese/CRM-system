import 'package:flutter/material.dart';

// A screen for customers to view and edit their profile information.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;

  // --- Database Integration Placeholder ---
  @override
  void initState() {
    super.initState();
    _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    // TODO: Implement database call to get the current customer's data.
    // try {
    //   final userId = FirebaseAuth.instance.currentUser?.uid;
    //   if (userId == null) return;
    //
    //   final doc = await FirebaseFirestore.instance.collection('customers').doc(userId).get();
    //   if (doc.exists) {
    //     final data = doc.data()!;
    //     _nameController.text = data['name'] ?? '';
    //     _emailController.text = data['email'] ?? '';
    //     _phoneController.text = data['phone'] ?? '';
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to load profile: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }

    // Mock loading behavior. The delay has been removed to improve load time.
    _nameController.text = "Alex Doe";
    _emailController.text = "alex.doe@example.com";
    _phoneController.text = "123-456-7890";
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    // TODO: Implement database call to update the customer's profile data.
    // try {
    //   final userId = FirebaseAuth.instance.currentUser?.uid;
    //   if (userId == null) return;
    //
    //   await FirebaseFirestore.instance.collection('customers').doc(userId).update({
    //     'name': _nameController.text,
    //     'email': _emailController.text,
    //     'phone': _phoneController.text,
    //     // Add other fields as necessary
    //   });
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Profile updated successfully!')),
    //   );
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to save profile: $e')),
    //   );
    // }
    print('Saving profile...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile changes saved (mock)!')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF182D53),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF182D53),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
