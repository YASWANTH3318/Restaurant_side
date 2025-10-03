import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/restaurant_auth_service.dart';
import '../models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '99220041339@klu.ac.in');
  final _passwordController = TextEditingController(text: '99220041339');
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'restaurant';

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Starting Google Sign-In flow...');
      
      // Proceed with restaurant sign-in directly
      final userCredential = await RestaurantAuthService.signInWithGoogleRestaurant();
      
      if (userCredential == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google sign-in was cancelled.';
        });
        return;
      }
      
      print('Google Sign-In successful, navigating to restaurant home...');
      
      if (!mounted) return;
      
      // Restaurant-only navigation
      Navigator.pushReplacementNamed(context, '/restaurant/home');
    } catch (e) {
      print('Google Sign-In Error: $e');
      
      if (!mounted) return;
      
      setState(() {
        if (e.toString().contains('account-exists-with-different-credential')) {
          _errorMessage = 'This email is already used with a different sign-in method. Try another login method.';
        } else if (e.toString().contains('ERROR_ABORTED_BY_USER') || e.toString().contains('cancelled')) {
          _errorMessage = 'Google sign-in was cancelled by user.';
        } else if (e.toString().contains('network_error') || e.toString().contains('network')) {
          _errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('invalid-credential')) {
          _errorMessage = 'Unable to authenticate with Google. Please try again.';
        } else if (e.toString().contains('user-disabled')) {
          _errorMessage = 'This account has been disabled. Please contact support.';
        } else if (e.toString().contains('operation-not-allowed')) {
          _errorMessage = 'Google Sign-In is not enabled. Please contact support.';
        } else if (e.toString().contains('popup_closed_by_user')) {
          _errorMessage = 'Sign-in popup was closed. Please try again.';
        } else if (e.toString().contains('popup_blocked_by_browser')) {
          _errorMessage = 'Sign-in popup was blocked. Please allow popups and try again.';
        } else if (e.toString().contains('sign_in_failed')) {
          _errorMessage = 'Google Sign-In failed. Please try again.';
        } else if (e.toString().contains('sign_in_canceled')) {
          _errorMessage = 'Google Sign-In was canceled. Please try again.';
        } else if (e.toString().contains('sign_in_required')) {
          _errorMessage = 'Please sign in to continue.';
        } else if (e.toString().contains('permission-denied')) {
          _errorMessage = 'Database permission denied. Please contact support.';
        } else if (e.toString().contains('Failed to set up restaurant account')) {
          _errorMessage = 'Failed to set up restaurant account. Please contact support.';
        } else {
          _errorMessage = 'Google Sign-In failed: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkEmailWithRole(String email, String selectedRole) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return false; // Email doesn't exist yet, allow login
      }
      
      // If user document exists but doesn't have metadata.role or it's the same as selected role, allow login
      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final existingRole = userData['metadata']?['role'] as String?;
        
        // If there's no role set or it matches the selected role, login is allowed
        if (existingRole == null || existingRole == selectedRole) {
          return false; // Role is compatible, allow login
        }
      }
      
      // Email exists with an incompatible role
      return true;
    } catch (e) {
      print('Error checking email role: $e');
      return false; // In case of error, allow the login
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        // Use RestaurantAuthService for restaurant authentication
        final result = await RestaurantAuthService.signInRestaurant(
          email: email,
          password: password,
        );
        
        if (mounted) {
          if (result['success'] == true) {
            if (result['needsProfileSetup'] == true) {
              // New user - redirect to profile setup
              final isNewUser = result['isNewUser'] ?? false;
              final message = result['message'] ?? 'Please complete your restaurant profile setup';
              
              // Show a brief message about what's happening
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isNewUser ? 'Welcome! Setting up your restaurant account...' : message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              Navigator.pushReplacementNamed(context, '/restaurant/profile-setup');
            } else {
              // Existing user - go to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome back!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.pushReplacementNamed(context, '/restaurant/home');
            }
          } else {
            setState(() {
              _errorMessage = result['error'] ?? 'Login failed. Please try again.';
              _isLoading = false;
            });
          }
        }
      } on FirebaseAuthException catch (authError) {
        print('Firebase Auth Error: $authError');
        if (mounted) {
          setState(() {
            switch (authError.code) {
              case 'user-not-found':
                _errorMessage = 'No account found with this email. Please sign up first.';
                break;
              case 'wrong-password':
                _errorMessage = 'Incorrect password. Please try again.';
                break;
              case 'invalid-email':
                _errorMessage = 'Invalid email address. Please check your email.';
                break;
              case 'user-disabled':
                _errorMessage = 'This account has been disabled. Please contact support.';
                break;
              case 'too-many-requests':
                _errorMessage = 'Too many failed attempts. Please try again later.';
                break;
              case 'invalid-credential':
                _errorMessage = 'The supplied auth credentials are incorrect, malformed or has expired. Please try again or contact support if the issue persists.';
                break;
              default:
                _errorMessage = authError.message ?? 'Authentication failed. Please try again.';
            }
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Login Error: $e');
        print('Error type: ${e.runtimeType}');
        if (mounted) {
          setState(() {
            // Check for specific error types
            if (e.toString().contains('Failed to set up restaurant account')) {
              _errorMessage = 'Failed to set up restaurant account. Please try again or contact support.';
            } else if (e.toString().contains('User is not authorized for restaurant access')) {
              _errorMessage = 'This account is not authorized for restaurant access. Please contact support.';
            } else if (e.toString().contains('Restaurant account is deactivated')) {
              _errorMessage = 'Your restaurant account has been deactivated. Please contact support.';
            } else if (e.toString().contains('network') || e.toString().contains('connection')) {
              _errorMessage = 'Network error. Please check your internet connection.';
            } else if (e.toString().contains('permission')) {
              _errorMessage = 'Permission denied. Please contact support.';
            } else if (e.toString().contains('timeout')) {
              _errorMessage = 'Request timed out. Please try again.';
            } else if (e.toString().contains('firestore') || e.toString().contains('database')) {
              _errorMessage = 'Database error. Please try again later.';
            } else {
              _errorMessage = 'Login failed: ${e.toString()}';
            }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Greedy Bites',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Restaurant-only app
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
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
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.red,
                      ),
                      label: const Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(context, '/signup');
                          },
                    child: const Text('Don\'t have an account? Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 