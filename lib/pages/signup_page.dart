import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/restaurant_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '99220041339@klu.ac.in');
  final _passwordController = TextEditingController(text: '99220041339');
  final _nameController = TextEditingController(text: 'Test User');
  final _usernameController = TextEditingController(text: 'testuser');
  final _phoneController = TextEditingController(text: '99220041339');
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'customer'; // Default role

  Future<void> _handleSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();

        // Check if email is already used with a different role
        final isEmailUsedWithDifferentRole =
            await UserService.isEmailUsedWithRole(email, _selectedRole);

        if (isEmailUsedWithDifferentRole) {
          setState(() {
            _errorMessage =
                'This email is already registered with a different role. Please use a different email.';
            _isLoading = false;
          });
          return;
        }

        // Check if username is available
        final isUsernameAvailable = await UserService.isUsernameAvailable(
          _usernameController.text.trim(),
        );

        if (!isUsernameAvailable) {
          setState(() {
            _errorMessage = 'Username is already taken';
            _isLoading = false;
          });
          return;
        }

        // Create restaurant user with RestaurantAuthService
        final userCredential = await RestaurantAuthService.signUpRestaurant(
          email: email,
          password: _passwordController.text.trim(),
          restaurantName: _nameController.text.trim(),
          ownerName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: null, // Can be added later
        );

        if (mounted) {
          if (_selectedRole == 'restaurant') {
            // For restaurants, navigate to restaurant details page for additional info
            Navigator.pushReplacementNamed(context, '/restaurant/home');

            // Show a dialog asking to complete the restaurant profile
            Future.delayed(const Duration(milliseconds: 500), () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Complete Your Restaurant Profile'),
                    content: const Text(
                      'Please complete your restaurant profile to make it visible to customers. Would you like to do this now?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/restaurant/details');
                        },
                        child: const Text('Yes, Complete Now'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Later'),
                      ),
                    ],
                  );
                },
              );
            });
          } else {
            // For other users, navigate to home page
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Error: $e');
        setState(() {
          switch (e.code) {
            case 'email-already-in-use':
              _errorMessage = 'This email is already registered. Please use a different email or try logging in.';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email address. Please check your email format.';
              break;
            case 'weak-password':
              _errorMessage = 'Password is too weak. Please choose a stronger password.';
              break;
            case 'operation-not-allowed':
              _errorMessage = 'Email/password accounts are not enabled. Please contact support.';
              break;
            case 'too-many-requests':
              _errorMessage = 'Too many attempts. Please try again later.';
              break;
            default:
              _errorMessage = e.message ?? 'An error occurred during sign up. Please try again.';
          }
        });
      } catch (e) {
        print('Signup Error: $e');
        print('Error type: ${e.runtimeType}');
        setState(() {
          // Check for specific error types
          if (e.toString().contains('username')) {
            _errorMessage = 'Username is already taken. Please choose a different username.';
          } else if (e.toString().contains('email')) {
            _errorMessage = 'Email validation failed. Please check your email.';
          } else if (e.toString().contains('network') || e.toString().contains('connection')) {
            _errorMessage = 'Network error. Please check your internet connection.';
          } else if (e.toString().contains('permission')) {
            _errorMessage = 'Permission denied. Please contact support.';
          } else if (e.toString().contains('timeout')) {
            _errorMessage = 'Request timed out. Please try again.';
          } else if (e.toString().contains('firestore') || e.toString().contains('database')) {
            _errorMessage = 'Database error. Please try again later.';
          } else {
            _errorMessage = 'Signup failed: ${e.toString()}';
          }
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Text(
                  'Select Your Role',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Role selection segment
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'customer',
                      label: Text('Customer'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 'blogger',
                      label: Text('Blogger'),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment(
                      value: 'restaurant',
                      label: Text('Restaurant'),
                      icon: Icon(Icons.restaurant),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Sign Up as ${_selectedRole.substring(0, 1).toUpperCase() + _selectedRole.substring(1)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
