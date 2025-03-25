import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pre_order.dart';

class PreOrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'pre_orders';

  // Create a new pre-order
  static Future<PreOrder> createPreOrder({
    required String restaurantId,
    required String userId,
    required String reservationId,
    required List<PreOrderItem> items,
    required double totalAmount,
  }) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      final now = DateTime.now();
      
      final preOrder = PreOrder(
        id: doc.id,
        restaurantId: restaurantId,
        userId: userId,
        reservationId: reservationId,
        items: items,
        totalAmount: totalAmount,
        createdAt: now,
        updatedAt: now,
        status: 'pending',
      );

      await doc.set(preOrder.toMap());
      return preOrder;
    } catch (e) {
      print('Error creating pre-order: $e');
      rethrow;
    }
  }

  // Get pre-orders for a reservation
  static Future<List<PreOrder>> getPreOrdersForReservation(String reservationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('reservationId', isEqualTo: reservationId)
          .get();

      return snapshot.docs
          .map((doc) => PreOrder.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting pre-orders: $e');
      return [];
    }
  }

  // Update pre-order status
  static Future<void> updatePreOrderStatus(String preOrderId, String status) async {
    try {
      await _firestore.collection(_collection).doc(preOrderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating pre-order status: $e');
      rethrow;
    }
  }

  // Delete pre-order
  static Future<void> deletePreOrder(String preOrderId) async {
    try {
      await _firestore.collection(_collection).doc(preOrderId).delete();
    } catch (e) {
      print('Error deleting pre-order: $e');
      rethrow;
    }
  }
} 