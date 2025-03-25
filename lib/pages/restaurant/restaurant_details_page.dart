import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import 'restaurant_home_page.dart';
import '../../services/restaurant_service.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final VoidCallback? onSubmitComplete;

  const RestaurantDetailsPage({
    super.key,
    this.onSubmitComplete,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = true; // Always true to show form directly
  File? _imageFile;
  String? _imageUrl;

  // Basic Info Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Address Controllers
  final TextEditingController _shopNoController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _colonyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // Timing Controllers
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();

  List<String> _selectedCuisineTypes = [];
  final List<String> _availableCuisineTypes = [
    'North Indian',
    'South Indian',
    'Chinese',
    'Italian',
    'Mexican',
    'Thai',
    'Japanese',
    'Continental',
    'Fast Food',
    'Desserts',
    'Beverages'
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  @override
  void dispose() {
    // Basic Info
    _nameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    // Address
    _shopNoController.dispose();
    _landmarkController.dispose();
    _colonyController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    // Timing
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            // Basic Info
            _nameController.text = data['name'] ?? '';
            _ownerNameController.text = data['ownerName'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _emailController.text = data['email'] ?? '';

            // Address
            _shopNoController.text = data['shopNo'] ?? '';
            _landmarkController.text = data['landmark'] ?? '';
            _colonyController.text = data['colony'] ?? '';
            _cityController.text = data['city'] ?? '';
            _stateController.text = data['state'] ?? '';
            _pincodeController.text = data['pincode'] ?? '';

            // Timing
            _openingTimeController.text = data['openingTime'] ?? '';
            _closingTimeController.text = data['closingTime'] ?? '';

            // Image and Cuisine
            _imageUrl = data['image'];
            _selectedCuisineTypes = List<String>.from(data['cuisineTypes'] ?? []);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading restaurant data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final String formattedTime = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpeningTime) {
          _openingTimeController.text = formattedTime;
        } else {
          _closingTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> _saveRestaurantDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not found');

      // Make image optional
      String? imageUrl;
      if (_imageFile != null) {
        try {
          imageUrl = await StorageService.uploadRestaurantImage(_imageFile!, user.uid);
        } catch (e) {
          print('Error uploading image: $e');
          // Continue without image if upload fails
        }
      }

      // Construct full address for easier display
      final fullAddress = [
        _shopNoController.text,
        _colonyController.text,
        _landmarkController.text,
        _cityController.text,
        _stateController.text,
        _pincodeController.text,
      ].where((element) => element.isNotEmpty).join(', ');

      final restaurantData = {
        // Basic Info
        'name': _nameController.text,
        'ownerName': _ownerNameController.text,
        'description': _descriptionController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,

        // Address
        'shopNo': _shopNoController.text,
        'landmark': _landmarkController.text,
        'colony': _colonyController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'fullAddress': fullAddress,

        // Other Details
        'cuisineTypes': _selectedCuisineTypes,
        'openingTime': _openingTimeController.text,
        'closingTime': _closingTimeController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'restaurant', // Add role to identify restaurant users
      };

      // Only add image URL if it exists
      if (imageUrl != null) {
        restaurantData['image'] = imageUrl;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        restaurantData['image'] = _imageUrl!;
      }

      // Save to users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(restaurantData, SetOptions(merge: true));

      // Sync data to restaurants collection
      await RestaurantService.syncRestaurantData(user.uid, restaurantData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant details saved successfully')),
        );
        
        // Return to dashboard
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving restaurant details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Restaurant'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
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
                    Text(
                      'Welcome to Greedy Bites!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please fill in your restaurant details to get started',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Restaurant Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null && _imageUrl == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo, size: 50),
                                    SizedBox(height: 8),
                                    Text('Add Restaurant Image'),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    _buildSectionTitle('Basic Information'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter restaurant name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contact Information Section
                    _buildSectionTitle('Contact Information'),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Address Section
                    _buildSectionTitle('Restaurant Address'),
                    TextFormField(
                      controller: _shopNoController,
                      decoration: const InputDecoration(
                        labelText: 'Shop No/Building Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shop number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _colonyController,
                      decoration: const InputDecoration(
                        labelText: 'Colony/Street Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter colony name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: const InputDecoration(
                              labelText: 'Pincode*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter pincode';
                              }
                              if (value.length != 6) {
                                return 'Pincode must be 6 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Restaurant Details Section
                    _buildSectionTitle('Restaurant Details'),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Tell us about your restaurant...',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter restaurant description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Cuisine Types
                    _buildSectionTitle('Cuisine Types'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCuisineTypes.map((cuisine) {
                        final isSelected = _selectedCuisineTypes.contains(cuisine);
                        return FilterChip(
                          label: Text(cuisine),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCuisineTypes.add(cuisine);
                              } else {
                                _selectedCuisineTypes.remove(cuisine);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Operating Hours
                    _buildSectionTitle('Operating Hours'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _openingTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Opening Time*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            readOnly: true,
                            onTap: () => _selectTime(context, true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select opening time';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _closingTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Closing Time*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            readOnly: true,
                            onTap: () => _selectTime(context, false),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select closing time';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveRestaurantDetails,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'Save & Proceed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 