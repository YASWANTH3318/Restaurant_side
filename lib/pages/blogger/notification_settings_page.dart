import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../utils/date_format_util.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final docSnapshot = await UserService.getUserData(_userId);
      final userData = docSnapshot.data() as Map<String, dynamic>;
      
      // Get notification settings or create default settings if they don't exist
      _settings = userData['notificationSettings'] as Map<String, dynamic>? ?? {
        'postLikes': true,
        'comments': true,
        'newFollowers': true,
        'bookingUpdates': true,
        'mentions': true,
        'directMessages': true,
        'contentRecommendations': true,
        'bloggerUpdates': true,
        'emailNotifications': true,
        'pushNotifications': true,
        'postRecap': true,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
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
      
      // Update notification settings in Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'notificationSettings': _settings});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
                  // General notification toggle
                  _buildToggleSetting(
                    'Push Notifications',
                    'Receive notifications on your device',
                    'pushNotifications',
                  ),
                  _buildToggleSetting(
                    'Email Notifications',
                    'Receive notifications via email',
                    'emailNotifications',
                  ),
                  const Divider(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Content Interactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggleSetting(
                    'Post Likes',
                    'When someone likes your post',
                    'postLikes',
                  ),
                  _buildToggleSetting(
                    'Comments',
                    'When someone comments on your post',
                    'comments',
                  ),
                  _buildToggleSetting(
                    'Mentions',
                    'When someone mentions you in a post or comment',
                    'mentions',
                  ),
                  const Divider(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Network',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggleSetting(
                    'New Followers',
                    'When someone follows you',
                    'newFollowers',
                  ),
                  _buildToggleSetting(
                    'Direct Messages',
                    'When you receive a direct message',
                    'directMessages',
                  ),
                  const Divider(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Business',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggleSetting(
                    'Booking Updates',
                    'Updates on restaurant bookings you\'ve made',
                    'bookingUpdates',
                  ),
                  const Divider(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'App Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggleSetting(
                    'Content Recommendations',
                    'Get personalized content recommendations',
                    'contentRecommendations',
                  ),
                  _buildToggleSetting(
                    'App Updates',
                    'News about new features and updates',
                    'bloggerUpdates',
                  ),
                  const Divider(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Summary & Digests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggleSetting(
                    'Weekly Post Recap',
                    'Weekly summary of your post performance',
                    'postRecap',
                  ),
                  
                  const SizedBox(height: 24),
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
                ],
              ),
            ),
    );
  }
} 