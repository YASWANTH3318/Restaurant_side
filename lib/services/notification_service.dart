import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/date_format_util.dart';
import '../config/restaurant_database_structure.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a notification for a restaurant when a table reservation is made
  static Future<void> createReservationNotification({
    required String restaurantId,
    required String reservationId,
    required String customerName,
    required String reservationDate,
    required String reservationTime,
    required int numberOfGuests,
    String? specialRequests,
    String? tableType,
  }) async {
    try {
      final notificationData = {
        'type': 'reservation',
        'title': 'New Table Reservation Request',
        'message': '$customerName wants to reserve a table for $numberOfGuests guests on $reservationDate at $reservationTime',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'reservationData': {
          'id': reservationId,
          'customerName': customerName,
          'reservationDate': reservationDate,
          'reservationTime': reservationTime,
          'numberOfGuests': numberOfGuests,
          'specialRequests': specialRequests,
          'tableType': tableType,
        },
      };

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(restaurantId)
          .collection('notifications')
          .add(notificationData);

      print('Reservation notification created for restaurant: $restaurantId');
    } catch (e) {
      print('Error creating reservation notification: $e');
      rethrow;
    }
  }

  /// Create a notification for a restaurant when a food order is placed
  static Future<void> createOrderNotification({
    required String restaurantId,
    required String orderId,
    required String customerName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final itemNames = items.map((item) => item['name'] ?? 'Unknown Item').join(', ');
      final notificationData = {
        'type': 'order',
        'title': 'New Food Order',
        'message': '$customerName placed an order for ${DateFormatUtil.formatCurrencyIndian(totalAmount)} - $itemNames',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'orderData': {
          'id': orderId,
          'customerName': customerName,
          'totalAmount': totalAmount,
          'items': items,
        },
      };

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(restaurantId)
          .collection('notifications')
          .add(notificationData);

      print('Order notification created for restaurant: $restaurantId');
    } catch (e) {
      print('Error creating order notification: $e');
      rethrow;
    }
  }

  /// Create a notification for a restaurant when a review is added
  static Future<void> createReviewNotification({
    required String restaurantId,
    required String reviewId,
    required String customerName,
    required double rating,
    String? reviewText,
  }) async {
    try {
      final notificationData = {
        'type': 'review',
        'title': 'New Review Received',
        'message': '$customerName gave you a ${rating.toStringAsFixed(1)} star rating${reviewText != null ? ' with a review' : ''}',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'reviewData': {
          'id': reviewId,
          'customerName': customerName,
          'rating': rating,
          'reviewText': reviewText,
        },
      };

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(restaurantId)
          .collection('notifications')
          .add(notificationData);

      print('Review notification created for restaurant: $restaurantId');
    } catch (e) {
      print('Error creating review notification: $e');
      rethrow;
    }
  }

  /// Create a system notification for a restaurant
  static Future<void> createSystemNotification({
    required String restaurantId,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'type': 'system',
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(restaurantId)
          .collection('notifications')
          .add(notificationData);

      print('System notification created for restaurant: $restaurantId');
    } catch (e) {
      print('Error creating system notification: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      print('Notification marked as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for the current restaurant
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Get unread notification count for the current restaurant
  static Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection(RestaurantDatabaseStructure.restaurants)
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get all notifications for the current restaurant
  static Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection(RestaurantDatabaseStructure.restaurants)
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }
} 