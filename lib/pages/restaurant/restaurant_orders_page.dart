import 'package:flutter/material.dart';

class RestaurantOrdersPage extends StatefulWidget {
  const RestaurantOrdersPage({super.key});

  @override
  State<RestaurantOrdersPage> createState() => _RestaurantOrdersPageState();
}

class _RestaurantOrdersPageState extends State<RestaurantOrdersPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Add dummy data for demonstration
    _orders = [
      {
        'id': 'ORD-1001',
        'customerName': 'John Doe',
        'items': [
          {'name': 'Caesar Salad', 'quantity': 1, 'price': 8.99},
          {'name': 'Grilled Salmon', 'quantity': 2, 'price': 18.99},
        ],
        'total': 46.97,
        'status': 'Pending',
        'time': DateTime.now().subtract(const Duration(minutes: 5)),
        'type': 'Delivery',
        'address': '123 Main St, New York, NY 10001',
        'phone': '+1 (555) 123-4567',
      },
      {
        'id': 'ORD-1002',
        'customerName': 'Jane Smith',
        'items': [
          {'name': 'Iced Tea', 'quantity': 2, 'price': 2.99},
          {'name': 'Chocolate Cake', 'quantity': 1, 'price': 6.99},
        ],
        'total': 12.97,
        'status': 'Preparing',
        'time': DateTime.now().subtract(const Duration(minutes: 15)),
        'type': 'Pickup',
        'phone': '+1 (555) 987-6543',
      },
      {
        'id': 'ORD-1003',
        'customerName': 'Mike Johnson',
        'items': [
          {'name': 'Grilled Salmon', 'quantity': 1, 'price': 18.99},
          {'name': 'Caesar Salad', 'quantity': 1, 'price': 8.99},
          {'name': 'Iced Tea', 'quantity': 1, 'price': 2.99},
        ],
        'total': 30.97,
        'status': 'Ready',
        'time': DateTime.now().subtract(const Duration(minutes: 30)),
        'type': 'Delivery',
        'address': '456 Elm St, New York, NY 10002',
        'phone': '+1 (555) 234-5678',
      },
      {
        'id': 'ORD-1004',
        'customerName': 'Sarah Williams',
        'items': [
          {'name': 'Chocolate Cake', 'quantity': 2, 'price': 6.99},
        ],
        'total': 13.98,
        'status': 'Completed',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'type': 'Pickup',
        'phone': '+1 (555) 345-6789',
      },
      {
        'id': 'ORD-1005',
        'customerName': 'David Brown',
        'items': [
          {'name': 'Grilled Salmon', 'quantity': 3, 'price': 18.99},
          {'name': 'Iced Tea', 'quantity': 3, 'price': 2.99},
        ],
        'total': 65.94,
        'status': 'Cancelled',
        'time': DateTime.now().subtract(const Duration(hours: 3)),
        'type': 'Delivery',
        'address': '789 Oak St, New York, NY 10003',
        'phone': '+1 (555) 456-7890',
      },
    ];
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredOrders(String status) {
    if (status == 'All') {
      return _orders;
    }
    return _orders.where((order) => order['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // TODO: Implement search
                        },
                      ),
                    ],
                  ),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Preparing'),
                    Tab(text: 'Ready'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList('All'),
                      _buildOrdersList('Pending'),
                      _buildOrdersList('Preparing'),
                      _buildOrdersList('Ready'),
                      _buildOrdersList('Completed'),
                      _buildOrdersList('Cancelled'),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildOrdersList(String status) {
    final orders = _getFilteredOrders(status);
    
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $status orders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    IconData statusIcon;
    
    switch (order['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'Preparing':
        statusColor = Colors.blue;
        statusIcon = Icons.restaurant;
        break;
      case 'Ready':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Completed':
        statusColor = Colors.green.shade800;
        statusIcon = Icons.done_all;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        childrenPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              order['id'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    order['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order['customerName']} • ${_formatTime(order['time'])}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order['type']} • \$${order['total'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        children: [
          // Order items
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                (order['items'] as List).length,
                (index) {
                  final item = order['items'][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['quantity']}x ${item['name']}'),
                        Text('\$${(item['quantity'] * item['price']).toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${order['total'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              // Customer details
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.person, order['customerName']),
              _buildDetailRow(Icons.phone, order['phone']),
              if (order['type'] == 'Delivery')
                _buildDetailRow(Icons.location_on, order['address']),
              
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> order) {
    final status = order['status'];
    final List<Widget> buttons = [];
    
    if (status == 'Pending') {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.restaurant),
          label: const Text('Start Preparing'),
          onPressed: () => _updateOrderStatus(order, 'Preparing'),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
          onPressed: () => _updateOrderStatus(order, 'Cancelled'),
        ),
      );
    } else if (status == 'Preparing') {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark as Ready'),
          onPressed: () => _updateOrderStatus(order, 'Ready'),
        ),
      );
    } else if (status == 'Ready') {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.done_all),
          label: const Text('Complete Order'),
          onPressed: () => _updateOrderStatus(order, 'Completed'),
        ),
      );
    }
    
    return buttons;
  }

  void _updateOrderStatus(Map<String, dynamic> order, String newStatus) {
    setState(() {
      order['status'] = newStatus;
    });
    
    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} updated to $newStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
} 