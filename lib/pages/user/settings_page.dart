import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default settings
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationServicesEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'INR (₹)';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First try to get settings from SharedPreferences for app appearance settings
      final prefs = await SharedPreferences.getInstance();
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedCurrency = prefs.getString('currency') ?? 'INR (₹)';
      
      // Then get user-specific settings from Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('user_settings').doc(user.uid);
        final doc = await docRef.get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _settings = data;
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _emailNotificationsEnabled = data['emailNotificationsEnabled'] ?? true;
            _locationServicesEnabled = data['locationServicesEnabled'] ?? true;
          });
        } else {
          // Create default settings document if it doesn't exist
          await docRef.set({
            'notificationsEnabled': _notificationsEnabled,
            'emailNotificationsEnabled': _emailNotificationsEnabled,
            'locationServicesEnabled': _locationServicesEnabled,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
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
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save app appearance settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkModeEnabled);
      await prefs.setString('language', _selectedLanguage);
      await prefs.setString('currency', _selectedCurrency);
      
      // Save user-specific settings to Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_settings').doc(user.uid).update({
          'notificationsEnabled': _notificationsEnabled,
          'emailNotificationsEnabled': _emailNotificationsEnabled,
          'locationServicesEnabled': _locationServicesEnabled,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
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
  
  Future<void> _deleteAccount() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      // Add another confirmation for safety
      final bool finalConfirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Final Confirmation'),
          content: const Text(
            'This will permanently delete your account and all associated data. Type "DELETE" to confirm.',
          ),
          actions: [
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type DELETE here',
              ),
              onSubmitted: (value) {
                Navigator.pop(context, value == 'DELETE');
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // This will be handled by the TextField submission
                  },
                  child: const Text(
                    'Confirm Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ) ?? false;
      
      if (finalConfirm) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Delete user data from Firestore
          final user = _auth.currentUser;
          if (user != null) {
            // Delete user settings
            await _firestore.collection('user_settings').doc(user.uid).delete();
            
            // Delete user profile
            await _firestore.collection('users').doc(user.uid).delete();
            
            // Delete user reservations, reviews, etc.
            // This would be better handled by a Cloud Function in a real app
            
            // Delete user account
            await user.delete();
            
            // Navigate to login page
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          print('Error deleting account: $e');
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete account: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  _buildSectionHeader('Notifications'),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive order updates and promotions'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive order confirmations and receipts by email'),
                    value: _emailNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _emailNotificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  
                  // App Preferences Section
                  _buildSectionHeader('App Preferences'),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme for the app'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      // Note: Implementing actual dark mode would require a theme provider
                    },
                  ),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showLanguageSelector(),
                  ),
                  ListTile(
                    title: const Text('Currency'),
                    subtitle: Text(_selectedCurrency),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showCurrencySelector(),
                  ),
                  const Divider(),
                  
                  // Privacy Section
                  _buildSectionHeader('Privacy & Location'),
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: const Text('Allow app to access your location for better restaurant recommendations'),
                    value: _locationServicesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationServicesEnabled = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to privacy policy page
                      // This would typically be a WebView or a static content page
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy Policy'),
                          content: const Text('Our privacy policy will be displayed here.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to terms of service page
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Terms of Service'),
                          content: const Text('Our terms of service will be displayed here.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  // Account Section
                  _buildSectionHeader('Account'),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  ListTile(
                    title: const Text('Delete Account'),
                    textColor: Colors.red,
                    trailing: const Icon(Icons.delete_forever, color: Colors.red),
                    onTap: _deleteAccount,
                  ),
                  const Divider(),
                  
                  // App Information
                  _buildSectionHeader('About'),
                  ListTile(
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    title: const Text('Rate the App'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Open app store or play store link
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Would launch app store link')),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Send Feedback'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Open feedback form or email
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Would open feedback form')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam', 'Kannada', 'Bengali'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector() {
    final currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'JPY (¥)'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: _selectedCurrency,
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate passwords
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Change password
              try {
                final user = _auth.currentUser;
                if (user != null && user.email != null) {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  
                  await user.reauthenticateWithCredential(credential);
                  
                  // Change password
                  await user.updatePassword(newPasswordController.text);
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error changing password: $e');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error changing password: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
} 