import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/date_format_util.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@greedybites.com',
      query: encodeQueryParameters({
        'subject': 'Restaurant Support Request - ${DateFormatUtil.formatDateIndian(DateTime.now())}'
      }),
    );
    
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email client');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+918800123456',
    );
    
    if (!await launchUrl(phoneLaunchUri)) {
      throw Exception('Could not launch phone dialer');
    }
  }
  
  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Help Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We are here to provide you with assistance and support for your restaurant business.',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Contact Us Card
          Card(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.contact_support, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@greedybites.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _launchEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Call Helpline'),
                  subtitle: const Text('+91 8800 123456'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _launchPhone,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Available 9 AM - 6 PM'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat will be available soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // FAQs Card
          Card(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.question_answer, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildExpandableFAQ(
                  context,
                  'How do I update my restaurant menu?',
                  'You can update your restaurant menu by navigating to the "Menu" tab in the bottom navigation bar. From there, you can add, edit, or remove menu items.'
                ),
                const Divider(height: 1),
                _buildExpandableFAQ(
                  context,
                  'How do I set my restaurant business hours?',
                  'You can set your business hours by going to the "Profile" tab, then tapping on "Business Hours". You can set different hours for each day of the week.'
                ),
                const Divider(height: 1),
                _buildExpandableFAQ(
                  context,
                  'How do I process an order?',
                  'When you receive a new order, it will appear in the "Orders" tab. You can view the details and update the status as you process the order from preparation to completion.'
                ),
                const Divider(height: 1),
                _buildExpandableFAQ(
                  context,
                  'How do payments work?',
                  'Customer payments are processed through our secure payment gateway. You will receive weekly settlements to your registered bank account with a detailed breakdown of all transactions.'
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Resources Card
          Card(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.library_books, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Resources',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('Restaurant Partner Guide'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchURL('https://greedybites.com/partner-guide'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Tutorial Videos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchURL('https://greedybites.com/tutorials'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchURL('https://greedybites.com/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchURL('https://greedybites.com/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // App Information
          Center(
            child: Column(
              children: [
                Text(
                  'Greedy Bites Restaurant Partner App',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildExpandableFAQ(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }
} 