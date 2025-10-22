import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeProfile extends StatefulWidget {
  const EmployeeProfile({super.key});

  @override
  _EmployeeProfileState createState() => _EmployeeProfileState();
}

class _EmployeeProfileState extends State<EmployeeProfile> {
  // Define a consistent dark blue color from the app's theme
  static const Color _primaryColor = Color(0xFF182D53);

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nameController = TextEditingController(text: "Alex"); // Initial value
  final _emailController = TextEditingController(text: "alex@example.com");
  final _phoneController = TextEditingController(text: "+1 234 567 890");

  // To hold the selected image file
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // --- DATABASE INTEGRATION TEMPLATE (START) ---
      // This is where you would handle the logic to save the user's data.
      //
      // 1. Upload the profile image if it has changed.
      // if (_profileImage != null) {
      //   // String imageUrl = await uploadImageToFirebaseStorage(_profileImage!);
      // }
      //
      // 2. Save the user data to your database (e.g., Firestore, SQL).
      // final userProfileData = {
      //   'name': _nameController.text,
      //   'email': _emailController.text,
      //   'phone': _phoneController.text,
      //   // 'profileImageUrl': imageUrl, // The URL from the uploaded image
      // };
      //
      // await saveUserDataToDatabase(userProfileData);
      //
      // --- DATABASE INTEGRATION TEMPLATE (END) ---

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    }
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 32),
              _buildTextFormField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }
}
