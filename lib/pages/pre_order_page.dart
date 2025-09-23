import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/pre_order.dart';
import '../services/pre_order_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreOrderPage extends StatefulWidget {
  final Restaurant restaurant;
  final String reservationId;
  final String userId;
  final DateTime reservationDate;
  final int numberOfGuests;

  const PreOrderPage({
    super.key,
    required this.restaurant,
    required this.reservationId,
    required this.userId,
    required this.reservationDate,
    required this.numberOfGuests,
  });

  @override
  State<PreOrderPage> createState() => _PreOrderPageState();
}

class _PreOrderPageState extends State<PreOrderPage> {
  final Map<String, int> _selectedItems = {};
  final Map<String, String> _specialInstructions = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-order Food'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePreOrder,
            ),
        ],
      ),
      body: Column(
        children: [
          // Reservation Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Date: ${widget.reservationDate.toString().split(' ')[0]}'),
                Text('Time: ${widget.reservationDate.toString().split(' ')[1].substring(0, 5)}'),
                Text('Guests: ${widget.numberOfGuests}'),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.restaurant.menu.length,
              itemBuilder: (context, index) {
                final category = widget.restaurant.menu.keys.elementAt(index);
                final items = widget.restaurant.menu[category]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) => _buildMenuItem(item)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          
          // Total Amount
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '₹${_calculateTotalAmount()}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final isSelected = _selectedItems.containsKey(item.name);
    final quantity = _selectedItems[item.name] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${item.price}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 0
                          ? () => _updateItemQuantity(item, quantity - 1)
                          : null,
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _updateItemQuantity(item, quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Special Instructions',
                  hintText: 'e.g., Extra spicy, no onions',
                ),
                onChanged: (value) => _specialInstructions[item.name] = value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateItemQuantity(MenuItem item, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedItems[item.name] = quantity;
      } else {
        _selectedItems.remove(item.name);
        _specialInstructions.remove(item.name);
      }
    });
  }

  double _calculateTotalAmount() {
    double total = 0;
    _selectedItems.forEach((itemName, quantity) {
      final item = widget.restaurant.menu.values
          .expand((items) => items)
          .firstWhere((item) => item.name == itemName);
      total += item.price * quantity;
    });
    return total;
  }

  Future<void> _savePreOrder() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final items = _selectedItems.entries.map((entry) {
        final item = widget.restaurant.menu.values
            .expand((items) => items)
            .firstWhere((item) => item.name == entry.key);
        
        return PreOrderItem(
          menuItemId: item.name, // Using name as ID for now
          name: item.name,
          price: item.price,
          quantity: entry.value,
          specialInstructions: _specialInstructions[entry.key],
        );
      }).toList();

      final preOrder = await PreOrderService.createPreOrder(
        restaurantId: widget.restaurant.id,
        userId: widget.userId,
        reservationId: widget.reservationId,
        items: items,
        totalAmount: _calculateTotalAmount(),
      );

      // Notifications for pre-order
      try {
        // Notify customer
        await NotificationService.createNotification(
          userId: widget.userId,
          title: 'Pre-order Placed',
          body: 'Your pre-order at ${widget.restaurant.name} has been placed',
          type: 'order',
          data: {
            'reservationId': widget.reservationId,
            'restaurantId': widget.restaurant.id,
            'preOrderId': preOrder.id,
            'totalAmount': preOrder.totalAmount,
          },
        );

        // Determine owner user id
        String ownerUserId = widget.restaurant.id;
        try {
          final doc = await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurant.id).get();
          final data = doc.data();
          if (data != null && data['ownerUserId'] is String) {
            ownerUserId = data['ownerUserId'];
          }
        } catch (_) {}

        // Notify restaurant owner
        await NotificationService.createNotification(
          userId: ownerUserId,
          title: 'New Pre-order',
          body: 'New pre-order received at ${widget.restaurant.name}',
          type: 'order_received',
          data: {
            'reservationId': widget.reservationId,
            'restaurantId': widget.restaurant.id,
            'preOrderId': preOrder.id,
            'totalAmount': preOrder.totalAmount,
            'byUserId': widget.userId,
          },
        );
      } catch (e) {
        // Ignore notification errors
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pre-order saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pre-order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 