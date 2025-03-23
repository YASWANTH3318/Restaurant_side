import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({super.key});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  bool _isLoading = false;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _shopNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cuisineController = TextEditingController();
  String? _profileImageUrl;
  List<String> _restaurantPhotos = [];
  
  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _shopNumberController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRestaurantDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await UserService.getUserData(user.uid);
        
        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;
          
          // Populate the form controllers with existing data
          setState(() {
            _nameController.text = data['name'] ?? '';
            _ownerNameController.text = data['ownerName'] ?? '';
            _shopNumberController.text = data['shopNumber'] ?? '';
            _landmarkController.text = data['landmark'] ?? '';
            _cityController.text = data['city'] ?? '';
            _stateController.text = data['state'] ?? '';
            _pincodeController.text = data['pincode'] ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _emailController.text = data['email'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            _cuisineController.text = data['cuisine'] ?? '';
            _profileImageUrl = data['profileImageUrl'];
            
            if (data['restaurantPhotos'] != null) {
              _restaurantPhotos = List<String>.from(data['restaurantPhotos']);
            } else {
              _restaurantPhotos = [];
            }
          });
        }
      }
    } catch (e) {
      print('Error loading restaurant details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurant details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveRestaurantDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get existing user data
        final userDoc = await UserService.getUserData(user.uid);
        Map<String, dynamic> userData;
        
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
        } else {
          userData = {
            'id': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'Restaurant',
            'createdAt': Timestamp.now(),
            'lastLoginAt': Timestamp.now(),
            'isEmailVerified': user.emailVerified,
            'metadata': {
              'role': 'restaurant',
              'createdAt': DateTime.now().toIso8601String(),
            },
          };
        }
        
        // Update with form data
        userData['name'] = _nameController.text;
        userData['ownerName'] = _ownerNameController.text;
        userData['shopNumber'] = _shopNumberController.text;
        userData['landmark'] = _landmarkController.text;
        userData['city'] = _cityController.text;
        userData['state'] = _stateController.text;
        userData['pincode'] = _pincodeController.text;
        userData['phoneNumber'] = _phoneController.text;
        userData['email'] = _emailController.text;
        userData['description'] = _descriptionController.text;
        userData['cuisine'] = _cuisineController.text;
        userData['restaurantPhotos'] = _restaurantPhotos;
        
        // Construct full address for easier querying
        userData['address'] = [
          _shopNumberController.text,
          _landmarkController.text,
          _cityController.text,
          _stateController.text,
          _pincodeController.text,
        ].where((element) => element.isNotEmpty).join(', ');
        
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant details saved successfully')),
          );
          setState(() {
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      print('Error saving restaurant details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving restaurant details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickAndUploadImage(bool isProfileImage) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // TODO: Implement image upload to Firebase Storage
        final String downloadUrl = 'https://example.com/placeholder.jpg'; // Replace with actual upload logic
        
        if (isProfileImage) {
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          
          // Update profile image URL in Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'profileImageUrl': downloadUrl,
            });
          }
        } else {
          setState(() {
            _restaurantPhotos.add(downloadUrl);
          });
          
          // Update restaurant photos in Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'restaurantPhotos': FieldValue.arrayUnion([downloadUrl]),
            });
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload feature coming soon')),
        );
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditForm()
              : _buildDetailsView(),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _saveRestaurantDetails,
              child: const Icon(Icons.save),
            )
          : null,
    );
  }
  
  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Image/Logo
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: _profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImageUrl == null
                      ? Center(
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'R',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _nameController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Restaurant Photos Gallery
          if (_restaurantPhotos.isNotEmpty) ...[
            const Text(
              'Restaurant Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _restaurantPhotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _restaurantPhotos[index],
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error_outline),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Owner Name
          if (_ownerNameController.text.isNotEmpty)
            _buildInfoSection(
              title: 'Owner Name',
              content: _ownerNameController.text,
              icon: Icons.person,
            ),
          
          // Address Information
          if (_shopNumberController.text.isNotEmpty || 
              _landmarkController.text.isNotEmpty || 
              _cityController.text.isNotEmpty || 
              _stateController.text.isNotEmpty || 
              _pincodeController.text.isNotEmpty) ...[
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_shopNumberController.text.isNotEmpty)
                    Text('Shop No: ${_shopNumberController.text}'),
                  if (_landmarkController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Landmark: ${_landmarkController.text}'),
                  ],
                  if (_cityController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('City: ${_cityController.text}'),
                  ],
                  if (_stateController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('State: ${_stateController.text}'),
                  ],
                  if (_pincodeController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Pincode: ${_pincodeController.text}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Phone
          if (_phoneController.text.isNotEmpty)
            _buildInfoSection(
              title: 'Phone',
              content: _phoneController.text,
              icon: Icons.phone,
            ),
          
          // Email
          _buildInfoSection(
            title: 'Email',
            content: _emailController.text,
            icon: Icons.email,
          ),
          
          // Cuisine
          if (_cuisineController.text.isNotEmpty)
            _buildInfoSection(
              title: 'Cuisine',
              content: _cuisineController.text,
              icon: Icons.restaurant_menu,
            ),
          
          // Description
          if (_descriptionController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _descriptionController.text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload (placeholder for future implementation)
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          image: _profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImageUrl == null
                            ? Center(
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'R',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: () => _pickAndUploadImage(true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profile Image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Restaurant Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Owner Name
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the restaurant owner name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Address Section
            const Text(
              'Address Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Shop Number
            TextFormField(
              controller: _shopNumberController,
              decoration: const InputDecoration(
                labelText: 'Shop Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your shop number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Landmark
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),
            
            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // State
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your state';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Pincode
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(
                labelText: 'Pincode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your pincode';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Contact Information
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your restaurant phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your restaurant email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Restaurant Information
            const Text(
              'Restaurant Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Cuisine
            TextFormField(
              controller: _cuisineController,
              decoration: const InputDecoration(
                labelText: 'Cuisine Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
                hintText: 'Italian, Chinese, Indian, etc.',
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Tell customers about your restaurant...',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            
            // Restaurant Photos
            const Text(
              'Restaurant Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Photo Gallery
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _restaurantPhotos.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == _restaurantPhotos.length) {
                    // Add photo button
                    return GestureDetector(
                      onTap: () => _pickAndUploadImage(false),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo),
                            SizedBox(height: 4),
                            Text('Add Photo'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Existing photo
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_restaurantPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _restaurantPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 