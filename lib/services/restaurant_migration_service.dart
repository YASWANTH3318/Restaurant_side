import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/restaurant_database_structure.dart';

class RestaurantMigrationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user needs migration from old structure to new restaurant structure
  static Future<bool> needsMigration(String uid) async {
    try {
      // Check if user exists in new restaurant_users collection
      final restaurantUserDoc = await _firestore
          .collection(RestaurantDatabaseStructure.restaurantUsers)
          .doc(uid)
          .get();

      if (restaurantUserDoc.exists) {
        return false; // User already migrated
      }

      // Check if user exists in old users collection
      final oldUserDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      return oldUserDoc.exists;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Migrate user from old structure to new restaurant structure
  static Future<bool> migrateUserToRestaurant(String uid) async {
    try {
      // Get user data from old collection
      final oldUserDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!oldUserDoc.exists) {
        print('User not found in old collection');
        return false;
      }

      final oldUserData = oldUserDoc.data()!;
      
      // Check if user was a restaurant user in old system
      final role = oldUserData['role'] as String?;
      if (role != 'restaurant') {
        print('User is not a restaurant user, cannot migrate');
        return false;
      }

      // Create restaurant user in new collection
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurantUsers)
          .doc(uid)
          .set({
        'uid': uid,
        'email': oldUserData['email'] ?? '',
        'restaurantName': oldUserData['name'] ?? oldUserData['restaurantName'] ?? 'Restaurant',
        'ownerName': oldUserData['name'] ?? 'Owner',
        'phoneNumber': oldUserData['phoneNumber'] ?? '',
        'address': oldUserData['address'],
        'role': 'restaurant_owner',
        'isActive': true,
        'createdAt': oldUserData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
        'version': '1.0',
        'migratedFrom': 'old_users_collection',
        'migratedAt': FieldValue.serverTimestamp(),
      });

      // Create main restaurant profile
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(uid)
          .set({
        'id': uid,
        'name': oldUserData['name'] ?? oldUserData['restaurantName'] ?? 'Restaurant',
        'ownerName': oldUserData['name'] ?? 'Owner',
        'email': oldUserData['email'] ?? '',
        'phoneNumber': oldUserData['phoneNumber'] ?? '',
        'address': oldUserData['address'],
        'isActive': true,
        'isVerified': false,
        'rating': 0.0,
        'totalReviews': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'createdAt': oldUserData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
        'version': '1.0',
        'migratedFrom': 'old_users_collection',
        'migratedAt': FieldValue.serverTimestamp(),
      });

      // Migrate existing data if any
      await _migrateExistingRestaurantData(uid, oldUserData);

      // Initialize restaurant subcollections
      await _initializeRestaurantSubcollections(uid);

      print('User successfully migrated to restaurant structure');
      return true;
    } catch (e) {
      print('Error migrating user: $e');
      return false;
    }
  }

  /// Migrate existing restaurant data from old structure
  static Future<void> _migrateExistingRestaurantData(String uid, Map<String, dynamic> oldUserData) async {
    try {
      // Migrate restaurant profile data
      final restaurantData = <String, dynamic>{};
      
      if (oldUserData['restaurantName'] != null) {
        restaurantData['name'] = oldUserData['restaurantName'];
      }
      if (oldUserData['address'] != null) {
        restaurantData['address'] = oldUserData['address'];
      }
      if (oldUserData['phoneNumber'] != null) {
        restaurantData['phoneNumber'] = oldUserData['phoneNumber'];
      }
      if (oldUserData['image'] != null) {
        restaurantData['image'] = oldUserData['image'];
      }
      if (oldUserData['description'] != null) {
        restaurantData['description'] = oldUserData['description'];
      }
      if (oldUserData['cuisine'] != null) {
        restaurantData['cuisine'] = oldUserData['cuisine'];
      }
      if (oldUserData['priceRange'] != null) {
        restaurantData['priceRange'] = oldUserData['priceRange'];
      }

      if (restaurantData.isNotEmpty) {
        restaurantData['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .update(restaurantData);
      }

      // Migrate menu items if they exist
      await _migrateMenuItems(uid);
      
      // Migrate tables if they exist
      await _migrateTables(uid);

    } catch (e) {
      print('Error migrating existing restaurant data: $e');
    }
  }

  /// Migrate menu items from old structure
  static Future<void> _migrateMenuItems(String uid) async {
    try {
      // Check if menu items exist in old structure
      final oldMenuDoc = await _firestore
          .collection('restaurants')
          .doc(uid)
          .get();

      if (!oldMenuDoc.exists) return;

      final oldData = oldMenuDoc.data()!;
      final menuItems = oldData['menu'] as List<dynamic>?;
      
      if (menuItems == null || menuItems.isEmpty) return;

      final batch = _firestore.batch();
      
      for (int i = 0; i < menuItems.length; i++) {
        final item = menuItems[i] as Map<String, dynamic>;
        final itemId = RestaurantDatabaseStructure.generateRestaurantDocumentId('menu_item');
        
        batch.set(
          _firestore
              .collection(RestaurantDatabaseStructure.restaurants)
              .doc(uid)
              .collection('menu')
              .doc(itemId),
          {
            'id': itemId,
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'dataType': 'restaurant',
            'migratedFrom': 'old_menu_structure',
          },
        );
      }

      await batch.commit();
      print('Migrated ${menuItems.length} menu items');
    } catch (e) {
      print('Error migrating menu items: $e');
    }
  }

  /// Migrate tables from old structure
  static Future<void> _migrateTables(String uid) async {
    try {
      // Check if tables exist in old structure
      final oldRestaurantDoc = await _firestore
          .collection('restaurants')
          .doc(uid)
          .get();

      if (!oldRestaurantDoc.exists) return;

      final oldData = oldRestaurantDoc.data()!;
      final tables = oldData['availableTables'] as List<dynamic>?;
      
      if (tables == null || tables.isEmpty) return;

      final batch = _firestore.batch();
      
      for (int i = 0; i < tables.length; i++) {
        final table = tables[i] as Map<String, dynamic>;
        final tableId = RestaurantDatabaseStructure.generateRestaurantDocumentId('table');
        
        batch.set(
          _firestore
              .collection(RestaurantDatabaseStructure.restaurants)
              .doc(uid)
              .collection('tables')
              .doc(tableId),
          {
            'id': tableId,
            ...table,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'dataType': 'restaurant',
            'migratedFrom': 'old_tables_structure',
          },
        );
      }

      await batch.commit();
      print('Migrated ${tables.length} tables');
    } catch (e) {
      print('Error migrating tables: $e');
    }
  }

  /// Initialize restaurant subcollections
  static Future<void> _initializeRestaurantSubcollections(String uid) async {
    try {
      final batch = _firestore.batch();

      // Initialize notifications
      batch.set(
        _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .collection('notifications')
            .doc('_init'),
        {'initialized': true, 'createdAt': FieldValue.serverTimestamp()},
      );

      // Initialize orders
      batch.set(
        _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .collection('orders')
            .doc('_init'),
        {'initialized': true, 'createdAt': FieldValue.serverTimestamp()},
      );

      // Initialize reservations
      batch.set(
        _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .collection('reservations')
            .doc('_init'),
        {'initialized': true, 'createdAt': FieldValue.serverTimestamp()},
      );

      // Initialize analytics
      batch.set(
        _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .collection('analytics')
            .doc('_init'),
        {'initialized': true, 'createdAt': FieldValue.serverTimestamp()},
      );

      // Initialize activities
      batch.set(
        _firestore
            .collection(RestaurantDatabaseStructure.restaurants)
            .doc(uid)
            .collection('activities')
            .doc('_init'),
        {'initialized': true, 'createdAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();
    } catch (e) {
      print('Error initializing restaurant subcollections: $e');
    }
  }

  /// Check if user can be migrated and migrate if possible
  static Future<bool> checkAndMigrateUser(String uid) async {
    try {
      final needsMig = await needsMigration(uid);
      if (needsMig) {
        return await migrateUserToRestaurant(uid);
      }
      return true; // User already migrated or doesn't need migration
    } catch (e) {
      print('Error checking and migrating user: $e');
      return false;
    }
  }

  /// Create a new restaurant user if migration fails
  static Future<bool> createNewRestaurantUser(String uid, String email, String name) async {
    try {
      // Create restaurant user in new collection
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurantUsers)
          .doc(uid)
          .set({
        'uid': uid,
        'email': email,
        'restaurantName': name,
        'ownerName': name,
        'phoneNumber': '',
        'role': 'restaurant_owner',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
        'version': '1.0',
        'createdAsNew': true,
      });

      // Create main restaurant profile
      await _firestore
          .collection(RestaurantDatabaseStructure.restaurants)
          .doc(uid)
          .set({
        'id': uid,
        'name': name,
        'ownerName': name,
        'email': email,
        'phoneNumber': '',
        'isActive': true,
        'isVerified': false,
        'rating': 0.0,
        'totalReviews': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dataType': 'restaurant',
        'version': '1.0',
        'createdAsNew': true,
      });

      // Initialize restaurant subcollections
      await _initializeRestaurantSubcollections(uid);

      print('Created new restaurant user');
      return true;
    } catch (e) {
      print('Error creating new restaurant user: $e');
      return false;
    }
  }
}
