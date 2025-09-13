import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class RestaurantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'restaurants';

  // Get featured restaurants
  static Future<List<Restaurant>> getFeaturedRestaurants() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isFeatured', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Restaurant.fromMap({...data, 'id': doc.id});
            })
            .toList();
      } else {
        // Return mock data if no restaurants found
        return _getMockRestaurants();
      }
    } catch (e) {
      print('Error getting featured restaurants: $e');
      // Return mock data on error
      return _getMockRestaurants();
    }
  }

  // Get popular restaurants
  static Future<List<Restaurant>> getPopularRestaurants() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Restaurant.fromMap({...data, 'id': doc.id});
            })
            .toList();
      } else {
        // Return mock data if no restaurants found
        return _getMockRestaurants();
      }
    } catch (e) {
      print('Error getting popular restaurants: $e');
      // Return mock data on error
      return _getMockRestaurants();
    }
  }

  // Get restaurant by ID
  static Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Restaurant.fromMap({...data, 'id': doc.id});
    } catch (e) {
      print('Error getting restaurant by ID: $e');
      rethrow;
    }
  }

  // Search restaurants
  static Future<List<Restaurant>> searchRestaurants(String query, {double? maxDistance}) async {
    try {
      print('Searching for restaurants with query: $query');
      final results = <Restaurant>[];
      
      // Normalize the search query
      final normalizedQuery = query.toLowerCase().trim();
      
      if (normalizedQuery.isEmpty) {
        // If query is empty, return popular restaurants instead
        return getPopularRestaurants();
      }

      // Get all restaurants from collection
      final snapshot = await _firestore.collection(_collection).get();
      print('Found ${snapshot.docs.length} restaurants in database');
      
      for (final doc in snapshot.docs) {
        if (!doc.exists) continue;
        
        final data = doc.data();
        if (data == null) continue;
        
        // Extract searchable fields
        final name = (data['name'] as String?)?.toLowerCase() ?? '';
        final cuisine = (data['cuisine'] as String?)?.toLowerCase() ?? '';
        final description = (data['description'] as String?)?.toLowerCase() ?? '';
        final address = (data['address'] as String?)?.toLowerCase() ?? '';
        
        // Get search tags if they exist
        List<String> searchTags = [];
        if (data['searchTags'] != null) {
          searchTags = List<String>.from(data['searchTags']);
        }
        
        // Check if restaurant matches search query directly by name (highest priority)
        bool hasExactNameMatch = name.contains(normalizedQuery);
        
        // Check if restaurant matches by any field
        bool hasMatch = hasExactNameMatch || 
            cuisine.contains(normalizedQuery) ||
            description.contains(normalizedQuery) ||
            address.contains(normalizedQuery) ||
            searchTags.any((tag) => tag.contains(normalizedQuery));
            
        if (hasMatch) {
          print('Found matching restaurant: ${data['name']}');
          try {
            final restaurant = Restaurant.fromMap({...data, 'id': doc.id});
            
            // If it's an exact name match, prioritize it
            if (hasExactNameMatch) {
              results.insert(0, restaurant);
            } else {
              results.add(restaurant);
            }
          } catch (e) {
            print('Error parsing restaurant data: $e');
          }
        }
      }

      print('Search returned ${results.length} results');
      return results;
    } catch (e) {
      print('Error searching restaurants: $e');
      return []; // Return empty list instead of throwing exception
    }
  }

  // Add sample restaurants to Firebase (only for development)
  static Future<bool> addSampleRestaurants() async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(_collection);

      // First, check if restaurants already exist to avoid duplicates
      final existingDocs = await collection
          .where('name', whereIn: _sampleRestaurants.map((r) => r.name).toList())
          .get();
      
      if (existingDocs.docs.isNotEmpty) {
        print('Some restaurants already exist. Skipping...');
        return false;
      }

      for (final restaurant in _sampleRestaurants) {
        final doc = collection.doc();
        final data = restaurant.toMap();
        // Ensure all required fields are non-null
        data['isFeatured'] = data['isFeatured'] ?? false;
        data['searchTags'] = data['searchTags'] ?? [];
        batch.set(doc, data);
      }

      await batch.commit();
      print('Sample restaurants added successfully');
      return true;
    } catch (e) {
      print('Error adding sample restaurants: $e');
      return false;
    }
  }

  static Future<List<Restaurant>> getRestaurantsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('foodType', isEqualTo: category.toLowerCase())
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Restaurant.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting restaurants by category: $e');
      return [];
    }
  }


  static Future<List<Restaurant>> getRestaurantsByCuisine(String cuisine) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('cuisine', isEqualTo: cuisine)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Restaurant.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting restaurants by cuisine: $e');
      return [];
    }
  }

  static Future<void> syncRestaurantData(String userId, Map<String, dynamic> restaurantData) async {
    try {
      // Convert user data to restaurant format
      final Map<String, dynamic> restaurantDoc = {
        'id': userId,
        'name': restaurantData['name'],
        'image': restaurantData['image'] ?? '',
        'cuisine': restaurantData['cuisineTypes']?.isNotEmpty == true 
            ? restaurantData['cuisineTypes'][0] 
            : 'Multi-Cuisine',
        'rating': 0.0, // New restaurants start with 0 rating
        'deliveryTime': '30-45 min', // Default delivery time
        'distance': 'Calculating...', // Will be calculated based on customer location
        'tags': restaurantData['cuisineTypes'] ?? [],
        'description': restaurantData['description'],
        'menu': {}, // Empty menu initially
        'availableTables': [], // Empty tables initially
        'openingHours': {
          'monday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'tuesday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'wednesday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'thursday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'friday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'saturday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
          'sunday': {'isOpen': true, 'openTime': restaurantData['openingTime'], 'closeTime': restaurantData['closingTime']},
        },
        'address': restaurantData['fullAddress'],
        'phoneNumber': restaurantData['phoneNumber'],
        'isFeatured': false,
        'searchTags': [
          restaurantData['name'].toLowerCase(),
          ...List<String>.from(restaurantData['cuisineTypes'] ?? []).map((type) => type.toLowerCase()),
          restaurantData['city']?.toLowerCase() ?? '',
          restaurantData['state']?.toLowerCase() ?? '',
          restaurantData['landmark']?.toLowerCase() ?? '',
          'restaurant', // Add a generic tag to find all restaurants
        ].where((tag) => tag.isNotEmpty).toList(),
        'location': {
          'city': restaurantData['city'],
          'state': restaurantData['state'],
          'pincode': restaurantData['pincode'],
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update or create restaurant document in restaurants collection
      await _firestore.collection('restaurants').doc(userId).set(restaurantDoc, SetOptions(merge: true));
      
      print('Restaurant data synced successfully for: ${restaurantData['name']}');
    } catch (e) {
      print('Error syncing restaurant data: $e');
      throw e;
    }
  }

  static Future<void> updateRestaurantMenu(String restaurantId, List<Map<String, dynamic>> menuItems) async {
    try {
      // Organize menu items by category
      final Map<String, List<Map<String, dynamic>>> menuByCategory = {};
      
      for (final item in menuItems) {
        final category = item['category'] ?? 'Other';
        if (!menuByCategory.containsKey(category)) {
          menuByCategory[category] = [];
        }
        menuByCategory[category]!.add({
          'name': item['name'],
          'description': item['description'],
          'price': item['price'],
          'image': item['image'] ?? '',
          'isVegetarian': item['isVegetarian'] ?? false,
          'isVegan': item['isVegan'] ?? false,
          'isSpicy': item['isSpicy'] ?? false,
          'allergens': item['allergens'] ?? [],
        });
      }

      // Update restaurant document with new menu
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'menu': menuByCategory,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating restaurant menu: $e');
      throw e;
    }
  }

  static Future<void> updateRestaurantTables(String restaurantId, List<Map<String, dynamic>> tables) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'availableTables': tables,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating restaurant tables: $e');
      throw e;
    }
  }

  static Future<void> updateRestaurantHours(String restaurantId, Map<String, dynamic> hours) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'openingHours': hours,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating restaurant hours: $e');
      throw e;
    }
  }
}

// Sample restaurant data
final List<Restaurant> _sampleRestaurants = [
  Restaurant(
    id: '1',
    name: 'The Spice Garden',
    image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
    cuisine: 'Indian • Traditional',
    rating: 4.5,
    deliveryTime: '30-40 min',
    distance: '2.5 km',
    tags: ['Spicy', 'Vegetarian Options'],
    description: 'Authentic Indian cuisine with a modern twist.',
    menu: {
      'Starters': [
        MenuItem(
          name: 'Samosa',
          description: 'Crispy pastry filled with spiced potatoes and peas',
          price: 5.99,
          allergens: ['Gluten'],
          isVegetarian: true,
        ),
      ],
    },
    availableTables: [
      TableType(
        id: 't1',
        capacity: 4,
        type: 'Standard',
        isAvailable: true,
        minimumSpend: 50.0,
      ),
    ],
    openingHours: OpeningHours(
      weeklyHours: {
        'monday': DayHours(
          isOpen: true,
          openTime: '11:00',
          closeTime: '22:00',
        ),
      },
    ),
    address: '123 Spice Street',
    phoneNumber: '+1234567890',
    isFeatured: true,
    searchTags: ['indian', 'spicy', 'vegetarian', 'traditional'],
  ),
  
  // Tamil Nadu Restaurant

];

// Firebase Structure:
/*
restaurants (collection)
  |- restaurantId (document)
      |- name: string
      |- image: string
      |- cuisine: string
      |- rating: number
      |- deliveryTime: string
      |- distance: string
      |- tags: array<string>
      |- description: string
      |- isFeatured: boolean
      |- searchTags: array<string> (lowercase tags for better search)
      |- menu: {
          categoryName: [{
            name: string,
            description: string,
            price: number,
            image: string?,
            allergens: array<string>,
            isVegetarian: boolean,
            isVegan: boolean,
            isSpicy: boolean
          }]
        }
      |- availableTables: [{
          id: string,
          capacity: number,
          type: string,
          isAvailable: boolean,
          minimumSpend: number
        }]
      |- openingHours: {
          dayName: {
            isOpen: boolean,
            openTime: string,
            closeTime: string,
            breakStartTime: string?,
            breakEndTime: string?
          }
        }
      |- address: string
      |- phoneNumber: string

reviews (collection)
  |- reviewId (document)
      |- userId: string
      |- userName: string
      |- userImage: string
      |- restaurantId: string
      |- rating: number
      |- comment: string
      |- date: timestamp
*/

  // Mock restaurants for demo purposes
  List<Restaurant> _getMockRestaurants() {
    return [
      Restaurant(
        id: 'mock1',
        name: 'Delicious Bites',
        description: 'Amazing food with great ambiance',
        address: '123 Main Street, City',
        phoneNumber: '+1234567890',
        rating: 4.5,
        image: 'https://picsum.photos/400/300?random=1',
        cuisine: 'Italian',
        deliveryTime: '30 min',
        distance: '2.5 km',
        tags: ['italian', 'mediterranean', 'fine-dining'],
        menu: {},
        availableTables: [],
        openingHours: OpeningHours(weeklyHours: {}),
      ),
      Restaurant(
        id: 'mock2',
        name: 'Spice Garden',
        description: 'Authentic Indian cuisine',
        address: '456 Oak Avenue, City',
        phoneNumber: '+1234567891',
        rating: 4.3,
        image: 'https://picsum.photos/400/300?random=2',
        cuisine: 'Indian',
        deliveryTime: '25 min',
        distance: '1.8 km',
        tags: ['indian', 'asian', 'spicy'],
        menu: {},
        availableTables: [],
        openingHours: OpeningHours(weeklyHours: {}),
      ),
    ];
  } 