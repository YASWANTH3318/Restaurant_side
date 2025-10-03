import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/date_format_util.dart';
import '../../services/notification_service.dart';

class RestaurantOrdersPage extends StatefulWidget {
  const RestaurantOrdersPage({super.key});

  @override
  State<RestaurantOrdersPage> createState() => _RestaurantOrdersPageState();
}

class _RestaurantOrdersPageState extends State<RestaurantOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedFoodOrderStatus = 'pending';
  
  // Food Orders Data
  List<Map<String, dynamic>> _foodOrders = [];
  
  // Table Reservations Data
  List<Map<String, dynamic>> _tableReservations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load data in parallel for better performance
      final futures = await Future.wait([
        // Load food orders using server-side query
        FirebaseFirestore.instance
            .collection('food_orders')
            .where('restaurantId', isEqualTo: user.uid)
            .where('status', isEqualTo: _selectedFoodOrderStatus)
            .orderBy('orderTime', descending: true)
            .limit(50) // Limit results for better performance
            .get(),
        
        // Load table reservations (client-side sort to avoid composite index)
        FirebaseFirestore.instance
            .collection('reservations')
            .where('restaurantId', isEqualTo: user.uid)
            .limit(50) // Limit results for better performance
            .get(),
      ]);

      final foodOrdersSnapshot = futures[0] as QuerySnapshot;
      final tableReservationsSnapshot = futures[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          _foodOrders = foodOrdersSnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return <String, dynamic>{'id': doc.id, ...?data};
              })
              .toList();
          
          _tableReservations = tableReservationsSnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return <String, dynamic>{'id': doc.id, ...?data};
              })
              .toList()
            ..sort((a, b) {
              final ta = a['createdAt'];
              final tb = b['createdAt'];
              final ma = (ta is Timestamp) ? ta.toDate() : DateTime.tryParse('$ta') ?? DateTime.fromMillisecondsSinceEpoch(0);
              final mb = (tb is Timestamp) ? tb.toDate() : DateTime.tryParse('$tb') ?? DateTime.fromMillisecondsSinceEpoch(0);
              return mb.compareTo(ma);
            });
          
          // Debug: Print reservation count
          print('Loaded ${_tableReservations.length} reservations for restaurant ${user.uid}');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _updateFoodOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('food_orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh orders
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }

  Future<void> _updateTableReservation(String reservationId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh reservations
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reservation: $e')),
        );
      }
    }
  }

  Widget _buildFoodOrdersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pending',
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: 'completed',
                  label: Text('Completed'),
                ),
                ButtonSegment(
                  value: 'cancelled',
                  label: Text('Cancelled'),
                ),
              ],
              selected: {_selectedFoodOrderStatus},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedFoodOrderStatus = selection.first;
                  _loadOrders();
                });
              },
            ),
          ),
        ),
        Expanded(child: _buildFoodOrdersList()),
      ],
    );
  }

  Widget _buildTableReservationsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Table Reservations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage incoming table reservation requests',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildTableReservationsList()),
      ],
    );
  }

  Widget _buildFoodOrdersList() {
    if (_foodOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedFoodOrderStatus} orders',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _foodOrders.length,
      itemBuilder: (context, index) {
        final order = _foodOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['id'].substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormatUtil.formatCurrencyIndian((order['totalAmount'] as num).toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${order['customerName']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Items: ${(order['items'] as List).length}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ordered: ${DateFormatUtil.formatDateTimeIndian(order['orderTime'].toDate())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (_selectedFoodOrderStatus == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _updateFoodOrderStatus(order['id'], 'cancelled'),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateFoodOrderStatus(order['id'], 'completed'),
                        child: const Text('Mark Completed'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildTableReservationsList() {
    // Ensure we only show actual reservations from database
    final validReservations = _tableReservations.where((reservation) {
      // Check if reservation has required fields and is not empty
      return reservation['id'] != null && 
             reservation['customerName'] != null && 
             reservation['customerName'].toString().isNotEmpty;
    }).toList();
    
    if (validReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No table reservations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When customers book tables, their requests will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'This page shows only real reservation requests from customers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: validReservations.length,
      itemBuilder: (context, index) {
        final reservation = validReservations[index];
        final status = reservation['status'] ?? 'pending';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Table for ${reservation['numberOfGuests'] ?? reservation['guests'] ?? 'N/A'} guests',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${reservation['customerName'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatReservationDate(reservation['reservationDate'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time: ${reservation['reservationTime'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (reservation['tableType'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Table Type: ${reservation['tableType']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (reservation['specialRequests'] != null && reservation['specialRequests'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Special Requests: ${reservation['specialRequests']}',
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Booked: ${_formatReservationDate(reservation['createdAt'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _updateTableReservation(reservation['id'], 'cancelled'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateTableReservation(reservation['id'], 'confirmed'),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ] else if (status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _updateTableReservation(reservation['id'], 'completed'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark Completed'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatReservationDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormatUtil.formatDateTimeIndian(date.toDate());
    }
    if (date is DateTime) {
      return DateFormatUtil.formatDateTimeIndian(date);
    }
    return date.toString();
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
      case 'completed':
        color = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Food Orders'),
            Tab(text: 'Table Reservations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFoodOrdersTab(),
                _buildTableReservationsTab(),
              ],
            ),
    );
  }
} 