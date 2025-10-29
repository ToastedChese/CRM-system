import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _avatarUrl;
  Uint8List? _newAvatarBytes; // To hold the new image locally for preview
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    final supabaseClient = Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You are not logged in.')),
      );
      return;
    }

    try {
      final data = await supabaseClient
          .from('employees')
          .select('first_name, last_name, phone, avatar_url')
          .eq('user_id', user.id)
          .single();

      if (!mounted) return;
      _nameController.text = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
      _emailController.text = user.email ?? '';
      _phoneController.text = data['phone'] ?? '';
      _avatarUrl = data['avatar_url'];
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
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

    if (croppedImageBytes == null) return;

    if (!mounted) return;
    setState(() {
      _newAvatarBytes = croppedImageBytes;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isSaving = true);

    final supabaseClient = Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Cannot save.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    String? newImageUrl;

    if (_newAvatarBytes != null) {
      try {
        const fileExt = 'png';
        final fileName = '${user.id}/profile.$fileExt';
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        await supabaseClient.storage.from('avatars').remove([fileName]);

        await supabaseClient.storage.from('avatars').uploadBinary(
              fileName,
              _newAvatarBytes!,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );

        final baseUrl = supabaseClient.storage.from('avatars').getPublicUrl(fileName);
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

    final updates = {
      'first_name': firstName,
      'last_name': lastName,
      'phone': _phoneController.text.trim(),
      if (newImageUrl != null) 'avatar_url': newImageUrl,
    };

    try {
      await supabaseClient.from('employees').update(updates).eq('user_id', user.id);

      if (mounted) {
        setState(() {
          if (newImageUrl != null) {
            _avatarUrl = newImageUrl;
            _newAvatarBytes = null; 
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    if (_newAvatarBytes != null) {
      backgroundImage = MemoryImage(_newAvatarBytes!);
    } else if (_avatarUrl != null) {
      backgroundImage = NetworkImage(_avatarUrl!);
    }

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
