import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/date_format_util.dart';

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
      if (user == null) return;

      // Load food orders using server-side query
      final foodOrdersSnapshot = await FirebaseFirestore.instance
          .collection('food_orders')
          .where('restaurantId', isEqualTo: user.uid)
          .where('status', isEqualTo: _selectedFoodOrderStatus)
          .orderBy('orderTime', descending: true)
          .get();

      // Load table reservations using server-side query
      final tableReservationsSnapshot = await FirebaseFirestore.instance
          .collection('table_reservations')
          .where('restaurantId', isEqualTo: user.uid)
          .orderBy('reservationTime', descending: true)
          .get();

      setState(() {
        _foodOrders = foodOrdersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        
        _tableReservations = tableReservationsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
          .collection('table_reservations')
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
                      '₹${order['totalAmount']}',
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
    if (_tableReservations.isEmpty) {
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tableReservations.length,
      itemBuilder: (context, index) {
        final reservation = _tableReservations[index];
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
                    Text(
                      'Table for ${reservation['guests']} guests',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${reservation['customerName']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateFormatUtil.formatDateIndian(reservation['reservationTime'].toDate())}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Time: ${DateFormatUtil.formatTimeIndian(reservation['reservationTime'].toDate())}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _updateTableReservation(reservation['id'], 'rejected'),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateTableReservation(reservation['id'], 'confirmed'),
                        child: const Text('Confirm'),
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
          : Column(
              children: [
                if (_tabController.index == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFoodOrdersList(),
                      _buildTableReservationsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 