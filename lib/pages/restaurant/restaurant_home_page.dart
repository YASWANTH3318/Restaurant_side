import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import 'restaurant_dashboard_page.dart';
import 'restaurant_menu_page.dart';
import 'restaurant_orders_page.dart';
import 'restaurant_profile_page.dart';
import 'restaurant_analytics_page.dart';
import 'restaurant_details_page.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const RestaurantDashboardPage(),
    const RestaurantMenuPage(),
    const RestaurantOrdersPage(),
    const RestaurantAnalyticsPage(),
    const RestaurantProfilePage(),
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRestaurantDetails();
  }

  Future<void> _checkRestaurantDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await UserService.getUserData(user.uid);
        
        if (!userData.exists || _isRestaurantDetailsMissing(userData.data() as Map<String, dynamic>)) {
          // If restaurant details are missing, navigate to the details page
          if (mounted) {
            _navigateToRestaurantDetails();
          }
        }
      }
    } catch (e) {
      print('Error checking restaurant details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isRestaurantDetailsMissing(Map<String, dynamic> userData) {
    // Check if essential restaurant details are missing
    return userData['name'] == null || 
           userData['name'].toString().isEmpty ||
           userData['phoneNumber'] == null || 
           userData['phoneNumber'].toString().isEmpty ||
           userData['address'] == null || 
           userData['address'].toString().isEmpty;
  }

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
  
  void _navigateToRestaurantDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RestaurantDetailsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Restaurant Details',
            onPressed: _navigateToRestaurantDetails,
          ),
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
            icon: Icon(Icons.restaurant_menu),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
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
} 