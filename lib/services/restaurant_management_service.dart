import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/restaurant_database_structure.dart';
import '../models/restaurant.dart';

class RestaurantManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // RESTAURANT PROFILE MANAGEMENT
  // ============================================================================

  /// Get current restaurant profile
  static Future<Map<String, dynamic>?> getCurrentRestaurantProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('Error getting current restaurant profile: $e');
      return null;
    }
  }

  /// Update restaurant profile
  static Future<void> updateRestaurantProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final validatedData = RestaurantDatabaseStructure.validateRestaurantData(updates);
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .update(validatedData);

      // Log activity
      await _logRestaurantActivity('profile_updated', 'Restaurant profile updated');
    } catch (e) {
      print('Error updating restaurant profile: $e');
      rethrow;
    }
  }

  /// Update restaurant business hours
  static Future<void> updateRestaurantHours(Map<String, dynamic> hours) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('business_hours')
          .doc('current')
          .set({
        ...hours,
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });

      await _logRestaurantActivity('hours_updated', 'Business hours updated');
    } catch (e) {
      print('Error updating restaurant hours: $e');
      rethrow;
    }
  }

  /// Update restaurant location
  static Future<void> updateRestaurantLocation(Map<String, dynamic> location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('locations')
          .doc('primary')
          .set({
        ...location,
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });

      await _logRestaurantActivity('location_updated', 'Restaurant location updated');
    } catch (e) {
      print('Error updating restaurant location: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESTAURANT MENU MANAGEMENT
  // ============================================================================

  /// Add menu item
  static Future<void> addMenuItem(Map<String, dynamic> menuItem) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final itemId = RestaurantDatabaseStructure.generateRestaurantDocumentId('menu_item');
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('menu')
          .doc(itemId)
          .set({
        'id': itemId,
        ...menuItem,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });

      await _logRestaurantActivity('menu_item_added', 'Menu item added: ${menuItem['name']}');
    } catch (e) {
      print('Error adding menu item: $e');
      rethrow;
    }
  }

  /// Update menu item
  static Future<void> updateMenuItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final validatedData = RestaurantDatabaseStructure.validateRestaurantData(updates);
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('menu')
          .doc(itemId)
          .update(validatedData);

      await _logRestaurantActivity('menu_item_updated', 'Menu item updated: $itemId');
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  /// Delete menu item
  static Future<void> deleteMenuItem(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('menu')
          .doc(itemId)
          .delete();

      await _logRestaurantActivity('menu_item_deleted', 'Menu item deleted: $itemId');
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }

  /// Get restaurant menu
  static Future<List<Map<String, dynamic>>> getRestaurantMenu() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('menu')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant menu: $e');
      return [];
    }
  }

  /// Add menu photo
  static Future<void> addMenuPhoto(String imageUrl, String caption) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final photoId = RestaurantDatabaseStructure.generateRestaurantDocumentId('menu_photo');
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('menu_photos')
          .doc(photoId)
          .set({
        'id': photoId,
        'imageUrl': imageUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });

      await _logRestaurantActivity('menu_photo_added', 'Menu photo added');
    } catch (e) {
      print('Error adding menu photo: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESTAURANT TABLE MANAGEMENT
  // ============================================================================

  /// Add table
  static Future<void> addTable(Map<String, dynamic> table) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tableId = RestaurantDatabaseStructure.generateRestaurantDocumentId('table');
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('tables')
          .doc(tableId)
          .set({
        'id': tableId,
        ...table,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });

      await _logRestaurantActivity('table_added', 'Table added: ${table['type']}');
    } catch (e) {
      print('Error adding table: $e');
      rethrow;
    }
  }

  /// Update table
  static Future<void> updateTable(String tableId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final validatedData = RestaurantDatabaseStructure.validateRestaurantData(updates);
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('tables')
          .doc(tableId)
          .update(validatedData);

      await _logRestaurantActivity('table_updated', 'Table updated: $tableId');
    } catch (e) {
      print('Error updating table: $e');
      rethrow;
    }
  }

  /// Delete table
  static Future<void> deleteTable(String tableId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('tables')
          .doc(tableId)
          .delete();

      await _logRestaurantActivity('table_deleted', 'Table deleted: $tableId');
    } catch (e) {
      print('Error deleting table: $e');
      rethrow;
    }
  }

  /// Get restaurant tables
  static Future<List<Map<String, dynamic>>> getRestaurantTables() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('tables')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant tables: $e');
      return [];
    }
  }

  // ============================================================================
  // RESTAURANT ORDERS MANAGEMENT
  // ============================================================================

  /// Get restaurant orders
  static Future<List<Map<String, dynamic>>> getRestaurantOrders({
    String status = 'all',
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant orders: $e');
      return [];
    }
  }

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logRestaurantActivity('order_status_updated', 'Order $orderId status updated to $status');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESTAURANT RESERVATIONS MANAGEMENT
  // ============================================================================

  /// Get restaurant reservations
  static Future<List<Map<String, dynamic>>> getRestaurantReservations({
    String status = 'all',
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('reservations')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant reservations: $e');
      return [];
    }
  }

  /// Update reservation status
  static Future<void> updateReservationStatus(String reservationId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logRestaurantActivity('reservation_status_updated', 'Reservation $reservationId status updated to $status');
    } catch (e) {
      print('Error updating reservation status: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESTAURANT ANALYTICS
  // ============================================================================

  /// Get restaurant analytics
  static Future<Map<String, dynamic>> getRestaurantAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('analytics')
          .doc('current')
          .get();

      if (!snapshot.exists) {
        return await _initializeRestaurantAnalytics();
      }

      return snapshot.data() ?? {};
    } catch (e) {
      print('Error getting restaurant analytics: $e');
      return {};
    }
  }

  /// Initialize restaurant analytics
  static Future<Map<String, dynamic>> _initializeRestaurantAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final analyticsData = {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'averageOrderValue': 0.0,
        'totalReservations': 0,
        'averageRating': 0.0,
        'totalReviews': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      };

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('analytics')
          .doc('current')
          .set(analyticsData);

      return analyticsData;
    } catch (e) {
      print('Error initializing restaurant analytics: $e');
      return {};
    }
  }

  // ============================================================================
  // RESTAURANT ACTIVITIES
  // ============================================================================

  /// Log restaurant activity
  static Future<void> _logRestaurantActivity(String type, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final activityId = RestaurantDatabaseStructure.generateRestaurantDocumentId('activity');
      
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('activities')
          .doc(activityId)
          .set({
        'id': activityId,
        'type': type,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
      });
    } catch (e) {
      print('Error logging restaurant activity: $e');
    }
  }

  /// Get restaurant activities
  static Future<List<Map<String, dynamic>>> getRestaurantActivities({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant activities: $e');
      return [];
    }
  }

  // ============================================================================
  // RESTAURANT NOTIFICATIONS
  // ============================================================================

  /// Get restaurant notifications
  static Future<List<Map<String, dynamic>>> getRestaurantNotifications({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting restaurant notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }
}
