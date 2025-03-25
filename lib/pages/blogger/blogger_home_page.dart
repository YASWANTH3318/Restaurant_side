import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'blogger_dashboard_page.dart';
import 'blogger_profile_page.dart';
import 'blogger_posts_page.dart';
import 'blogger_analytics_page.dart';
import 'blogger_restaurants_page.dart';
import 'create_post_page.dart';
import 'create_reel_page.dart';

class BloggerHomePage extends StatefulWidget {
  const BloggerHomePage({super.key});

  @override
  State<BloggerHomePage> createState() => _BloggerHomePageState();
}

class _BloggerHomePageState extends State<BloggerHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const BloggerDashboardPage(),
    const BloggerRestaurantsPage(),
    const BloggerPostsPage(),
    const BloggerAnalyticsPage(),
    const BloggerProfilePage(),
  ];

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await UserService.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_selectedIndex) {
      case 0:
        title = 'Blogger Dashboard';
        break;
      case 1:
        title = 'Explore Restaurants';
        break;
      case 2:
        title = 'My Posts';
        break;
      case 3:
        title = 'Analytics';
        break;
      case 4:
        title = 'Profile';
        break;
      default:
        title = 'Blogger Dashboard';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 
        ? FloatingActionButton(
            onPressed: () {
              // Show content creation options
              _showContentCreationOptions(context);
            },
            child: const Icon(Icons.add),
          )
        : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showContentCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.post_add),
                title: const Text('Create Post'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Create Reel'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateReelPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 