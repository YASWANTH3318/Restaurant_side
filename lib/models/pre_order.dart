import 'package:cloud_firestore/cloud_firestore.dart';

class PreOrder {
  final String id;
  final String restaurantId;
  final String userId;
  final String reservationId;
  final List<PreOrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'pending', 'confirmed', 'cancelled'

  PreOrder({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.reservationId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'userId': userId,
      'reservationId': reservationId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };
  }

  factory PreOrder.fromMap(Map<String, dynamic> map) {
    return PreOrder(
      id: map['id'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      userId: map['userId'] ?? '',
      reservationId: map['reservationId'] ?? '',
      items: (map['items'] as List?)
          ?.map((item) => PreOrderItem.fromMap(item))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}

class PreOrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  PreOrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory PreOrderItem.fromMap(Map<String, dynamic> map) {
    return PreOrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      specialInstructions: map['specialInstructions'],
    );
  }
} 