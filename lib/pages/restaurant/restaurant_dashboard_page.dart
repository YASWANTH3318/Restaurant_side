import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greedy_bites/pages/restaurant/restaurant_menu_page.dart';
import 'package:greedy_bites/pages/restaurant/restaurant_orders_page.dart';
import 'package:greedy_bites/pages/restaurant/restaurant_profile_page.dart';
import 'package:greedy_bites/pages/restaurant/restaurant_analytics_page.dart';
import '../../utils/date_format_util.dart';

class RestaurantDashboardPage extends StatefulWidget {
  const RestaurantDashboardPage({super.key});

  @override
  State<RestaurantDashboardPage> createState() => _RestaurantDashboardPageState();
}

class _RestaurantDashboardPageState extends State<RestaurantDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _greeting = '';
  String _restaurantName = '';
  bool _isLoading = true;
  
  // Stats
  int _totalOrders = 0;
  double _totalRevenue = 0;
  int _newCustomers = 0;
  double _avgRating = 0;
  
  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadRestaurantData();
  }
  
  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }
  
  Future<void> _loadRestaurantData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Set default values (zeros) for a new restaurant
        setState(() {
          _restaurantName = user.displayName ?? 'Restaurant Owner';
          _totalOrders = 0;
          _totalRevenue = 0;
          _newCustomers = 0;
          _avgRating = 0;
          _isLoading = false;
        });
        
        // In a real app, you would fetch this data from Firestore
        // final userDoc = await _firestore.collection('users').doc(user.uid).get();
        // if (userDoc.exists) {
        //   setState(() {
        //     _restaurantName = userDoc.data()?['restaurantName'] ?? 'Restaurant Owner';
        //     _isLoading = false;
        //   });
        // }
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _greeting,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _restaurantName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Orders',
                      _totalOrders.toString(),
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Revenue',
                      DateFormatUtil.formatCurrencyIndian(_totalRevenue),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'New Customers',
                      _newCustomers.toString(),
                      Icons.people,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Rating',
                      _avgRating.toString(),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Management section
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Management cards
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildManagementCard(
                    'Menu',
                    'Manage your food menu',
                    Icons.restaurant_menu,
                    Colors.deepOrange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RestaurantMenuPage()),
                    ),
                  ),
                  _buildManagementCard(
                    'Orders',
                    'Track & manage orders',
                    Icons.receipt_long,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RestaurantOrdersPage()),
                    ),
                  ),
                  _buildManagementCard(
                    'Analytics',
                    'View detailed analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RestaurantAnalyticsPage()),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent activity section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all activities
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Recent activities list
              _buildActivityItem(
                'New Order #1234',
                'John Doe placed a new order',
                '10 mins ago',
                Icons.receipt,
                Colors.blue,
              ),
              _buildActivityItem(
                'Order #1230 Completed',
                'Order was successfully delivered',
                '1 hour ago',
                Icons.check_circle,
                Colors.green,
              ),
              _buildActivityItem(
                'New Review',
                'Sarah gave your restaurant 5 stars',
                '3 hours ago',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    // Format numbers using Indian format if value is a number and not already formatted
    String displayValue = value;
    if (title == 'Orders' || title == 'New Customers') {
      try {
        final numValue = int.parse(value);
        displayValue = DateFormatUtil.formatNumberIndian(numValue);
      } catch (e) {
        // Not a number or already formatted, keep as is
      }
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 18,
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
    );
  }
  
  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
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
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 