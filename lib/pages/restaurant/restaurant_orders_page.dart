import 'package:flutter/material.dart';
import '../../utils/date_format_util.dart';

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
    _tabController = TabController(length: 6, vsync: this);
    
    // Empty orders list by default
    // For a real app, you would fetch orders from Firebase
    _orders = [];
    
    // Uncomment and modify this code when you want to test with sample data
    /*
    _orders = [
      {
        'id': 'ORD-1001',
        'customerName': 'John Doe',
        'items': [
          {'name': 'Caesar Salad', 'quantity': 1, 'price': 249},
          {'name': 'Grilled Salmon', 'quantity': 2, 'price': 599},
        ],
        'total': 1447,
        'status': 'Pending',
        'time': DateTime.now().subtract(const Duration(minutes: 5)),
        'type': 'Delivery',
        'address': '123 Main St, New Delhi, 110001',
        'phone': '+91 98765 43210',
      },
      // Add more sample orders as needed
    ];
    */
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
    return Scaffold(
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Preparing'),
                Tab(text: 'Ready'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          
          // Order lists
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
              'No $status orders yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status == 'All') ...[
              const SizedBox(height: 8),
              Text(
                'Orders will appear here when customers place them',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
    final statusColors = {
      'Pending': Colors.blue,
      'Preparing': Colors.orange,
      'Ready': Colors.green,
      'Completed': Colors.teal,
      'Cancelled': Colors.red,
    };
    
    final statusColor = statusColors[order['status']] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(order['customerName']),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_formatTime(order['time'])),
              ],
            ),
            const SizedBox(height: 8),
            
            // Order type
            Row(
              children: [
                Icon(
                  order['type'] == 'Delivery' ? Icons.delivery_dining : Icons.shopping_bag_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(order['type']),
                if (order['type'] == 'Delivery' && order['address'] != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['address'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            
            const Divider(height: 24),
            
            // Order items
            ...List.generate(
              (order['items'] as List).length,
              (index) {
                final item = order['items'][index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${item['quantity']}x'),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item['name'])),
                      Text(
                        DateFormatUtil.formatCurrencyIndian(item['price'] * item['quantity']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const Divider(height: 24),
            
            // Order total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormatUtil.formatCurrencyIndian(order['total']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (order['status'] != 'Completed' && order['status'] != 'Cancelled')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Update order status
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_getNextStatusText(order['status'])),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Cancel order
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  String _getNextStatusText(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return 'Accept & Prepare';
      case 'Preparing':
        return 'Mark as Ready';
      case 'Ready':
        return 'Complete Order';
      default:
        return 'Update Status';
    }
  }
  
  String _formatTime(DateTime time) {
    return DateFormatUtil.formatTimeIndian(time);
  }
} 