import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../utils/date_format_util.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _userData = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final docSnapshot = await UserService.getUserData(_userId);
      final userData = docSnapshot.data() as Map<String, dynamic>;
      
      _userData = userData;
      
      // Get account settings or create default settings if they don't exist
      _settings = userData['accountSettings'] as Map<String, dynamic>? ?? {
        'contentVisibility': 'public', // public, followers, private
        'allowComments': true,
        'allowDirectMessages': true,
        'showLocationData': true,
        'showProfileInSearch': true,
        'autoSaveDrafts': true,
        'defaultPostPrivacy': 'public',
        'language': 'English',
        'contentLanguage': 'English',
        'reviewReminders': true,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account settings: $e')),
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
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Update account settings in Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'accountSettings': _settings});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account settings: $e')),
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

  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset email: $e')),
        );
      }
    }
  }

  Widget _buildToggleSetting(String title, String description, String settingKey) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: Switch(
        value: _settings[settingKey] ?? true,
        onChanged: (value) {
          setState(() {
            _settings[settingKey] = value;
          });
        },
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title, 
    String description, 
    String settingKey, 
    List<String> options,
    Map<String, String> optionDescriptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(description),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: DropdownButtonFormField<String>(
            value: _settings[settingKey],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _settings[settingKey] = newValue;
                });
              }
            },
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value),
                    if (optionDescriptions.containsKey(value))
                      Text(
                        optionDescriptions[value]!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
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
                  // Account Information
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: const Text('Email'),
                            subtitle: Text(_auth.currentUser?.email ?? 'Not available'),
                            leading: const Icon(Icons.email),
                          ),
                          ListTile(
                            title: const Text('Username'),
                            subtitle: Text(_userData['username'] ?? 'Not set'),
                            leading: const Icon(Icons.person),
                          ),
                          ListTile(
                            title: const Text('Account Type'),
                            subtitle: const Text('Blogger'),
                            leading: const Icon(Icons.badge),
                          ),
                          ListTile(
                            title: const Text('Joined'),
                            subtitle: Text(
                              _userData['createdAt'] != null
                                  ? DateFormatUtil.formatDateIndian((_userData['createdAt'] as Timestamp).toDate())
                                  : 'Not available',
                            ),
                            leading: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Content Visibility
                  const Text(
                    'Content & Privacy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownSetting(
                    'Content Visibility',
                    'Who can see your posts by default',
                    'contentVisibility',
                    ['public', 'followers', 'private'],
                    {
                      'public': 'Anyone can see your posts',
                      'followers': 'Only your followers can see your posts',
                      'private': 'Only you can see your posts',
                    },
                  ),
                  _buildDropdownSetting(
                    'Default Post Privacy',
                    'Default privacy setting for new posts',
                    'defaultPostPrivacy',
                    ['public', 'followers', 'private'],
                    {
                      'public': 'Visible to everyone',
                      'followers': 'Visible to followers only',
                      'private': 'Only visible to you',
                    },
                  ),
                  _buildToggleSetting(
                    'Allow Comments',
                    'Allow others to comment on your posts',
                    'allowComments',
                  ),
                  _buildToggleSetting(
                    'Allow Direct Messages',
                    'Allow others to send you direct messages',
                    'allowDirectMessages',
                  ),
                  _buildToggleSetting(
                    'Show Location Data',
                    'Show location information in your posts',
                    'showLocationData',
                  ),
                  _buildToggleSetting(
                    'Profile Discoverability',
                    'Allow your profile to appear in search results',
                    'showProfileInSearch',
                  ),
                  const SizedBox(height: 32),
                  
                  // Preferences
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownSetting(
                    'Language',
                    'App language',
                    'language',
                    ['English', 'हिन्दी', 'मराठी', 'తెలుగు', 'தமிழ்', 'ಕನ್ನಡ', 'മലയാളം', 'ગુજરાતી', 'ਪੰਜਾਬੀ', 'বাংলা'],
                    {},
                  ),
                  _buildDropdownSetting(
                    'Content Language',
                    'Preferred language for your content',
                    'contentLanguage',
                    ['English', 'हिन्दी', 'मराठी', 'తెలుగు', 'தமிழ்', 'ಕನ್ನಡ', 'മലയാളം', 'ગુજરાતી', 'ਪੰਜਾਬੀ', 'বাংলা'],
                    {},
                  ),
                  _buildToggleSetting(
                    'Auto-save Drafts',
                    'Automatically save drafts while writing posts',
                    'autoSaveDrafts',
                  ),
                  _buildToggleSetting(
                    'Review Reminders',
                    'Get reminders to review restaurants you visited',
                    'reviewReminders',
                  ),
                  const SizedBox(height: 32),
                  
                  // Security Section
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Reset Password'),
                    subtitle: const Text('Send a password reset email'),
                    onTap: _resetPassword,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Delete Account
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account?'),
                            content: const Text(
                              'This action cannot be undone. All your data will be permanently deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Close dialog
                                  Navigator.pop(context);
                                  
                                  // Show confirmation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please contact support to delete your account'),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 