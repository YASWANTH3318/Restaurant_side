import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../utils/date_format_util.dart';
import 'create_post_page.dart';
import 'create_reel_page.dart';

class BloggerDashboardPage extends StatefulWidget {
  const BloggerDashboardPage({super.key});

  @override
  State<BloggerDashboardPage> createState() => _BloggerDashboardPageState();
}

class _BloggerDashboardPageState extends State<BloggerDashboardPage> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: FirebaseAuth.instance.currentUser != null 
                            ? UserService.getUserData(FirebaseAuth.instance.currentUser!.uid)
                            : Future.value(null),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            return Text(
                              'Welcome back, ${userData?['name'] ?? 'Blogger'}! 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return const Text('Welcome back! 👋');
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Here\'s what\'s happening with your blog today',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats row
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 32) / 3,
                        child: _buildStatCard('Total Posts', '0', Icons.article),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 32) / 3,
                        child: _buildStatCard('Views Today', '0', Icons.visibility),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 32) / 3,
                        child: _buildStatCard('Followers', '0', Icons.people),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Recent activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Empty state or list of activities
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first blog post to get started',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to create post page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.post_add),
                          label: const Text('Create Post'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to create reel page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateReelPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.video_library_outlined),
                          label: const Text('Create Reel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    // Format numbers using Indian format if they are numeric
    String displayValue = value;
    try {
      // Check if the value is a number
      final numValue = int.parse(value);
      displayValue = DateFormatUtil.formatNumberIndian(numValue);
    } catch (e) {
      // If not a number, use original value
      displayValue = value;
    }
    
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 