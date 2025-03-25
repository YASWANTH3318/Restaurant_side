import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/date_format_util.dart';

class RestaurantActivityPage extends StatefulWidget {
  const RestaurantActivityPage({super.key});

  @override
  State<RestaurantActivityPage> createState() => _RestaurantActivityPageState();
}

class _RestaurantActivityPageState extends State<RestaurantActivityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // In a real app, you would fetch activities from Firestore
      // Here we'll use sample data for demonstration
      
      // Mock data - these would normally come from Firestore
      final mockActivities = [
        {
          'type': 'order',
          'title': 'New Order Received',
          'description': 'Order #2384 for ₹450 has been placed',
          'time': DateTime.now().subtract(const Duration(minutes: 15)),
          'icon': Icons.receipt_long,
          'color': Colors.blue,
        },
        {
          'type': 'review',
          'title': 'New Review',
          'description': 'Rajesh gave your restaurant 4.5 stars',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
          'icon': Icons.star,
          'color': Colors.amber,
        },
        {
          'type': 'table',
          'title': 'Table Reservation',
          'description': 'Priya reserved a table for 4 people on Saturday',
          'time': DateTime.now().subtract(const Duration(hours: 3)),
          'icon': Icons.table_restaurant,
          'color': Colors.green,
        },
        {
          'type': 'menu',
          'title': 'Menu Updated',
          'description': 'You added "Paneer Tikka" to your menu',
          'time': DateTime.now().subtract(const Duration(hours: 6)),
          'icon': Icons.restaurant_menu,
          'color': Colors.orange,
        },
        {
          'type': 'profile',
          'title': 'Profile Updated',
          'description': 'You updated your restaurant description',
          'time': DateTime.now().subtract(const Duration(days: 1)),
          'icon': Icons.edit,
          'color': Colors.purple,
        },
        {
          'type': 'order',
          'title': 'Order Completed',
          'description': 'Order #2367 for ₹850 has been completed',
          'time': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          'icon': Icons.check_circle,
          'color': Colors.green,
        },
        {
          'type': 'promo',
          'title': 'Promotion Created',
          'description': 'You created a new promotion for weekend dinner',
          'time': DateTime.now().subtract(const Duration(days: 2)),
          'icon': Icons.local_offer,
          'color': Colors.red,
        },
        {
          'type': 'system',
          'title': 'System Update',
          'description': 'App updated with new features',
          'time': DateTime.now().subtract(const Duration(days: 3)),
          'icon': Icons.system_update,
          'color': Colors.teal,
        },
      ];

      setState(() {
        _activities = mockActivities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activities: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your restaurant activities will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return _buildActivityItem(
            title: activity['title'],
            description: activity['description'],
            time: activity['time'],
            icon: activity['icon'],
            color: activity['color'],
            type: activity['type'],
          );
        },
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String description,
    required DateTime time,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatUtil.formatRelativeTime(time),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'order':
        return 'ORDER';
      case 'review':
        return 'REVIEW';
      case 'table':
        return 'TABLE';
      case 'menu':
        return 'MENU';
      case 'profile':
        return 'PROFILE';
      case 'promo':
        return 'PROMO';
      case 'system':
        return 'SYSTEM';
      default:
        return type.toUpperCase();
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'review':
        return Colors.amber;
      case 'table':
        return Colors.green;
      case 'menu':
        return Colors.orange;
      case 'profile':
        return Colors.purple;
      case 'promo':
        return Colors.red;
      case 'system':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Activities'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All Activities', Icons.all_inclusive, Colors.blue),
              _buildFilterOption('Orders', Icons.receipt_long, Colors.blue),
              _buildFilterOption('Reviews', Icons.star, Colors.amber),
              _buildFilterOption('Table Reservations', Icons.table_restaurant, Colors.green),
              _buildFilterOption('Menu Updates', Icons.restaurant_menu, Colors.orange),
              _buildFilterOption('Profile Updates', Icons.edit, Colors.purple),
              _buildFilterOption('Promotions', Icons.local_offer, Colors.red),
              _buildFilterOption('System Updates', Icons.system_update, Colors.teal),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Implement filtering logic here
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
} 