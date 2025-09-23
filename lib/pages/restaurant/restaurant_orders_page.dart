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
  final Map<int, TextEditingController> _capacityCtrls = {
    2: TextEditingController(text: '0'),
    4: TextEditingController(text: '0'),
    6: TextEditingController(text: '0'),
    8: TextEditingController(text: '0'),
  };
  
  // Food Orders Data
  List<Map<String, dynamic>> _foodOrders = [];
  
  // Table Reservations Data
  List<Map<String, dynamic>> _tableReservations = [];
  String? _selectedSlotKey;
  Map<String, int> _slotAvailable = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _capacityCtrls.values) { c.dispose(); }
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

  Future<void> _loadSlotAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedSlotKey == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .collection('table_slots')
          .doc(_selectedSlotKey)
          .get();
      if (!mounted) return;
      final data = doc.data();
      setState(() {
        _slotAvailable = Map<String, int>.from((data?['available'] ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())));
      });
    } catch (_) {}
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

  Future<void> _openTotalsDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Total Tables by Capacity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final cap in [2,4,6,8])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text('${cap} seats')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _capacityCtrls[cap],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total tables',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final Map<int, int> totals = {};
                for (final entry in _capacityCtrls.entries) {
                  final val = int.tryParse(entry.value.text.trim()) ?? 0;
                  totals[entry.key] = val;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(user.uid)
                      .collection('table_totals')
                      .doc('base')
                      .set({
                    'totals': totals.map((k, v) => MapEntry(k.toString(), v)),
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Table totals saved')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving totals: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
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
                  'Date: ${DateFormatUtil.formatDateIndian((reservation['reservationDate'] as Timestamp).toDate())}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Time: ${reservation['reservationTime']}',
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
                      OutlinedButton.icon(
                        onPressed: () => _updateTableReservation(reservation['id'], 'completed'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete'),
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
        actions: [
          TextButton.icon(
            onPressed: _openTotalsDialog,
            icon: const Icon(Icons.event_seat, color: Colors.white),
            label: const Text('Totals', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                if (_tabController.index == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Slot to View Availability'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Slot (YYYYMMDD_HHMM)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => _selectedSlotKey = v.trim(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _loadSlotAvailability,
                              child: const Text('Load'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_slotAvailable.isNotEmpty)
                          Builder(builder: (context) {
                            final List<String> caps = _slotAvailable.keys.toList();
                            caps.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                            final chips = caps.map((k) => Chip(label: Text('${k}p: ${_slotAvailable[k]} available'))).toList();
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: chips,
                            );
                          }),
                      ],
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