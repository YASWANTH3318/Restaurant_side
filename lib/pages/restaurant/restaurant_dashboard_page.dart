import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greedy_bites/pages/restaurant/restaurant_tables_page.dart';
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

  String _formatRelativeTime(DateTime when) {
    final Duration diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    final int weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }

  _IconColor _iconForActivity(String type) {
    switch (type) {
      case 'order_created':
        return _IconColor(Icons.receipt_long, Colors.blue);
      case 'order_completed':
        return _IconColor(Icons.check_circle, Colors.green);
      case 'review_added':
        return _IconColor(Icons.star, Colors.amber);
      case 'table_updated':
        return _IconColor(Icons.table_restaurant, Colors.teal);
      default:
        return _IconColor(Icons.notifications, Colors.grey);
    }
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
        // Set default values immediately for fast loading
        setState(() {
          _restaurantName = user.displayName ?? 'Restaurant Owner';
          _totalOrders = 0;
          _totalRevenue = 0;
          _newCustomers = 0;
          _avgRating = 0;
          _isLoading = false;
        });
        
        // Try to load real data in background (non-blocking)
        _loadRealDataInBackground(user.uid);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRealDataInBackground(String uid) async {
    try {
      // Load real data without blocking UI
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        setState(() {
          _restaurantName = data?['name'] ?? data?['restaurantName'] ?? 'Restaurant Owner';
          // You can add more real data loading here
        });
      }
    } catch (e) {
      print('Error loading real restaurant data: $e');
      // Don't show error to user, just use defaults
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

              // Place the Tables shortcut under the Rating card (right column) styled like stat cards
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RestaurantTablesPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _buildStatCard(
                        'Tables',
                        'Manage',
                        Icons.table_restaurant,
                        Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
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
              
              // Recent activities list (dynamic)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _auth.currentUser == null
                    ? const Stream.empty()
                    : _firestore
                        .collection('restaurants')
                        .doc(_auth.currentUser!.uid)
                        .collection('activities')
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Failed to load activity',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No recent activity yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final data = d.data();
                      final String title = (data['title'] as String?) ?? 'Activity';
                      final String subtitle = (data['subtitle'] as String?) ?? '';
                      final Timestamp? ts = data['createdAt'] as Timestamp?;
                      final DateTime when = ts?.toDate() ?? DateTime.now();
                      final String time = _formatRelativeTime(when);
                      final String type = (data['type'] as String?) ?? 'generic';
                      final _IconColor iconColor = _iconForActivity(type);

                      return _buildActivityItem(
                        title,
                        subtitle,
                        time,
                        iconColor.icon,
                        iconColor.color,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 

class _IconColor {
  final IconData icon;
  final Color color;
  const _IconColor(this.icon, this.color);
}