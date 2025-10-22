import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // For image uploads
// import 'dart:io'; // For File class

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  static const Color mainBlue = Color(0xFF182D53);
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nameController = TextEditingController(text: 'Manager Name');
  final _emailController = TextEditingController(text: 'manager@powerlink.com');
  final _phoneController = TextEditingController(text: '081-234-5678');

  final bool _isLoading = false;
  // File? _profileImage;

  @override
  void initState() {
    super.initState();
    // _fetchManagerProfile(); // Fetch data when screen loads
  }

  // --- Database & Backend Placeholders ---
  /*
  Future<void> _fetchManagerProfile() async {
    setState(() => _isLoading = true);
    // In a real app, you'd fetch the manager's data from a database.
    // final managerData = await FirebaseFirestore.instance.collection('managers').doc(auth.currentUser.uid).get();
    // _nameController.text = managerData['name'];
    // _emailController.text = managerData['email'];
    // _phoneController.text = managerData['phone'];
    // setState(() { _profileImageUrl = managerData['profileImageUrl']; });
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // String? imageUrl;
      // if (_profileImage != null) {
      //   // Upload image to Firebase Storage and get URL
      //   // final ref = FirebaseStorage.instance.ref().child('manager_profiles').child(auth.currentUser.uid + '.jpg');
      //   // await ref.putFile(_profileImage!);
      //   // imageUrl = await ref.getDownloadURL();
      // }
      
      // Save data to Firestore
      // await FirebaseFirestore.instance.collection('managers').doc(auth.currentUser.uid).update({
      //   'name': _nameController.text,
      //   'email': _emailController.text,
      //   'phone': _phoneController.text,
      //   if (imageUrl != null) 'profileImageUrl': imageUrl,
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   setState(() {
    //     _profileImage = File(pickedFile.path);
    //   });
    // }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email Address', Icons.email, enabled: false),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {}, // _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
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
          const CircleAvatar(
            radius: 60,
            backgroundColor: mainBlue,
            // backgroundImage: _profileImage != null 
            //   ? FileImage(_profileImage!) 
            //   : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // _pickImage,
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.camera_alt, color: mainBlue, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: mainBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
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
