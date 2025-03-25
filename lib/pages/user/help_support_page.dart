import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to submit a support request')),
        );
        return;
      }
      
      // Get user data to include in support request
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      // Create support ticket in Firestore
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': userData['name'] ?? 'Unknown',
        'subject': _subjectController.text,
        'message': _messageController.text,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'resolved': false,
      });
      
      if (mounted) {
        // Clear form and show success message
        _subjectController.clear();
        _messageController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully. We\'ll get back to you soon!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit support request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@greedybites.com',
      queryParameters: {
        'subject': 'Customer Support Request',
      },
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get support or send us feedback',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Help Section
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Help',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Help Options
                  _buildHelpOption(
                    icon: Icons.restaurant,
                    title: 'Restaurant Issues',
                    subtitle: 'Problems with orders, menu, or restaurant information',
                    onTap: () => _showHelpDetails('restaurant'),
                  ),
                  const Divider(),
                  _buildHelpOption(
                    icon: Icons.payment,
                    title: 'Payment Issues',
                    subtitle: 'Problems with payments or refunds',
                    onTap: () => _showHelpDetails('payment'),
                  ),
                  const Divider(),
                  _buildHelpOption(
                    icon: Icons.delivery_dining,
                    title: 'Delivery Issues',
                    subtitle: 'Problems with food delivery or pickup',
                    onTap: () => _showHelpDetails('delivery'),
                  ),
                  const Divider(),
                  _buildHelpOption(
                    icon: Icons.account_circle,
                    title: 'Account Issues',
                    subtitle: 'Problems with your account or profile',
                    onTap: () => _showHelpDetails('account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Contact Us Section
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'support@greedybites.com',
              onTap: _launchEmail,
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+91 123-456-7890',
              onTap: () async {
                final Uri telUri = Uri(scheme: 'tel', path: '+911234567890');
                try {
                  await launchUrl(telUri);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch phone app')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 32),
            
            // Submit Ticket Form
            const Text(
              'Submit a Support Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subject),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      hintText: 'Describe your issue in detail',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSupportRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit Ticket'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // FAQs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/faq');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I cancel my order?',
              'You can cancel your order by going to the Orders tab and selecting the order you wish to cancel. Note that orders can only be canceled within 5 minutes of placing them or before the restaurant accepts the order.',
            ),
            _buildFaqItem(
              'How do I get a refund?',
              'Refunds are processed automatically for canceled orders. For issues with your order that require a refund, please contact our customer support team through this app or by email.',
            ),
            _buildFaqItem(
              'How do I change my delivery address?',
              'You can update your delivery address from your profile page by selecting "Delivery Address" and then adding or editing your addresses.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
  
  void _showHelpDetails(String type) {
    final Map<String, List<String>> helpDetails = {
      'restaurant': [
        'If your order is wrong or incomplete, contact the restaurant directly through the app',
        'For issues with restaurant information or menu, report it through the restaurant page',
        'If you need to cancel a reservation, do so at least 2 hours in advance'
      ],
      'payment': [
        'For payment failures, please try again with a different payment method',
        'Refunds typically take 5-7 business days to process',
        'For unauthorized charges, please contact our support team immediately'
      ],
      'delivery': [
        'If your delivery is delayed, you can track its status in the Orders tab',
        'For incorrect delivery address, contact the driver directly through the app',
        'If your food arrived cold or damaged, please take a photo and report it immediately'
      ],
      'account': [
        'To reset your password, use the "Forgot Password" option on the login screen',
        'To update your profile information, go to your Profile page',
        'If you cannot access your account, contact our support team with your email address'
      ],
    };
    
    final String title = {
      'restaurant': 'Restaurant Issues',
      'payment': 'Payment Issues',
      'delivery': 'Delivery Issues',
      'account': 'Account Issues',
    }[type] ?? 'Help';
    
    final List<String> details = helpDetails[type] ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (String detail in details) ...[
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(detail),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Scroll to support ticket form
              // This would need a ScrollController to implement in the real app
            },
            child: const Text('Get More Help'),
          ),
        ],
      ),
    );
  }
} 