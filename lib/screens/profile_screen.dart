import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:powerlink_crm/data/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _departmentController = TextEditingController();

  String? _avatarUrl;
  Uint8List? _newAvatarBytes;
  Map<String, dynamic>? _profileData; // Holds all profile data, including type and id

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Universal fetch method
  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await SupabaseService.getMyProfileData();
      if (!mounted) return;

      if (data == null) {
        final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a profile for your user.')),
        );
        _emailController.text = currentUserEmail ?? 'No email found';
        return;
      }

      setState(() {
        _profileData = data;
        _nameController.text = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        _emailController.text = data['email'] ?? Supabase.instance.client.auth.currentUser?.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _avatarUrl = data['avatar_url'];

        // Set role or department if they exist
        if (data.containsKey('role')) {
          _roleController.text = data['role'] ?? '';
        }
        if (data.containsKey('department')) {
          _departmentController.text = data['department'] ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    // This logic is universal and remains the same
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (imageFile == null) return;

    final croppedImageBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(image: File(imageFile.path)),
        fullscreenDialog: true,
      ),
    );

    if (croppedImageBytes == null || !mounted) return;

    setState(() {
      _newAvatarBytes = croppedImageBytes;
    });
  }

  // Universal save method
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !mounted) return;
    
    if (_profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save. Profile data not loaded.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please sign in again.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    String? newImageUrl;
    if (_newAvatarBytes != null) {
      try {
        const fileExt = 'png';
        // Use a unique path for each user's profile picture
        final fileName = '${user.id}/profile.$fileExt';
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        await Supabase.instance.client.storage.from('avatars').remove([fileName]);
        await Supabase.instance.client.storage.from('avatars').uploadBinary(
              fileName,
              _newAvatarBytes!,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );

        final baseUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        newImageUrl = '$baseUrl?t=$timestamp';
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading picture: $e')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final fullName = _nameController.text.trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final updates = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': _phoneController.text.trim(),
      if (newImageUrl != null) 'avatar_url': newImageUrl,
    };

    final userType = _profileData!['type'] as String?;

    try {
      int? recordId;
      Map<String, dynamic> result;

      switch (userType) {
        case 'employee':
          updates['role'] = _roleController.text.trim();
          recordId = _profileData!['employee_id'];
          result = await SupabaseService.updateEmployee(recordId!, updates);
          break;
        case 'customer':
          // Customer specific fields can be added here if needed
          recordId = _profileData!['customer_id'];
          result = await SupabaseService.updateCustomer(recordId!, updates);
          break;
        case 'manager':
          updates['department'] = _departmentController.text.trim();
          recordId = _profileData!['id'];
          result = await SupabaseService.updateManager(recordId!, updates);
          break;
        default:
          throw Exception('Unknown user type: $userType');
      }

      if (mounted) {
        setState(() {
          // Update local state with the saved data
          _profileData!.addAll(result);
          if (newImageUrl != null) {
            _avatarUrl = newImageUrl;
            _newAvatarBytes = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This build method is now universal
    ImageProvider? backgroundImage;
    if (_newAvatarBytes != null) {
      backgroundImage = MemoryImage(_newAvatarBytes!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_avatarUrl!);
    }

    final userType = _profileData?['type'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: backgroundImage,
                            child: backgroundImage == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                onPressed: _pickAvatar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Full Name cannot be empty.';
                        if (!value.trim().contains(' ')) return 'Please enter both first and last name.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        fillColor: Theme.of(context).disabledColor.withOpacity(0.1),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                    ),

                    if (userType == 'employee') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roleController,
                        decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                    ],

                    if (userType == 'manager') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), prefixIcon: Icon(Icons.apartment_outlined)),
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Update Profile'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CropScreen extends StatefulWidget {
  final File image;

  const CropScreen({super.key, required this.image});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = CropController(
    aspectRatio: 1,
    defaultCrop: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Picture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final ui.Image croppedImage = await _controller.croppedBitmap();
              final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
              final Uint8List? bytes = byteData?.buffer.asUint8List();
              
              if (mounted && bytes != null) {
                Navigator.pop(context, bytes);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CropImage(
            controller: _controller,
            image: Image.file(widget.image),
            gridColor: Colors.white70,
            gridCornerSize: 50,
            gridThinWidth: 2,
            gridThickWidth: 4,
            scrimColor: Colors.black54,
            alwaysShowThirdLines: true,
          ),
        ),
      ),
    );
  }
}
