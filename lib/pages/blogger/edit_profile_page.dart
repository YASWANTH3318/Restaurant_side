import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/date_format_util.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _specialtiesController = TextEditingController();
  
  bool _isLoading = false;
  File? _profileImage;
  String? _currentProfileImage;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    _nameController.text = widget.userData['name'] ?? '';
    _usernameController.text = widget.userData['username'] ?? '';
    _bioController.text = widget.userData['bio'] ?? '';
    _phoneController.text = widget.userData['phoneNumber'] ?? '';
    _currentProfileImage = widget.userData['profileImageUrl'];
    
    // Initialize social media fields
    final socialMedia = widget.userData['socialMedia'] as Map<String, dynamic>? ?? {};
    _websiteController.text = socialMedia['website'] ?? '';
    _facebookController.text = socialMedia['facebook'] ?? '';
    _instagramController.text = socialMedia['instagram'] ?? '';
    _twitterController.text = socialMedia['twitter'] ?? '';
    _youtubeController.text = socialMedia['youtube'] ?? '';
    
    // Initialize specialties
    final specialties = widget.userData['specialties'] as List<dynamic>? ?? [];
    _specialtiesController.text = specialties.join(', ');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return _currentProfileImage;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Upload profile image if changed
      final profileImageUrl = await _uploadProfileImage();
      
      // Parse specialties
      final specialties = _specialtiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // Create social media map
      final socialMedia = {
        'website': _websiteController.text,
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'twitter': _twitterController.text,
        'youtube': _youtubeController.text,
      };
      
      // Get existing user data to preserve fields we're not updating
      final docSnapshot = await UserService.getUserData(userId);
      final existingData = docSnapshot.data() as Map<String, dynamic>;
      
      // Update user data
      final updatedUserData = {
        ...existingData,
        'name': _nameController.text,
        'username': _usernameController.text,
        'bio': _bioController.text,
        'phoneNumber': _phoneController.text,
        'profileImageUrl': profileImageUrl,
        'specialties': specialties,
        'socialMedia': socialMedia,
        'updatedAt': Timestamp.now(),
      };
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updatedUserData);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage != null 
                              ? FileImage(_profileImage!) 
                              : (_currentProfileImage != null 
                                  ? NetworkImage(_currentProfileImage!) as ImageProvider 
                                  : null),
                          child: (_profileImage == null && _currentProfileImage == null)
                              ? Text(
                                  _nameController.text.isNotEmpty 
                                      ? _nameController.text[0].toUpperCase() 
                                      : 'B',
                                  style: const TextStyle(fontSize: 40),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Personal Information Section
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  
                  // Social Media Section
                  const Text(
                    'Social Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      prefixIcon: Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      labelText: 'Facebook',
                      prefixIcon: Icon(Icons.facebook),
                      hintText: 'Username or URL',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram',
                      prefixIcon: Icon(Icons.camera_alt),
                      hintText: 'Username without @',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _twitterController,
                    decoration: const InputDecoration(
                      labelText: 'Twitter',
                      prefixIcon: Icon(Icons.travel_explore),
                      hintText: 'Username without @',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _youtubeController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube',
                      prefixIcon: Icon(Icons.video_library),
                      hintText: 'Channel URL or name',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Food Specialties Section
                  const Text(
                    'Food Specialties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialtiesController,
                    decoration: const InputDecoration(
                      labelText: 'Food Specialties',
                      prefixIcon: Icon(Icons.restaurant_menu),
                      hintText: 'e.g. Italian, Desserts, Street Food (comma separated)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
} 