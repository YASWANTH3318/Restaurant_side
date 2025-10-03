import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/restaurant_database_structure.dart';

class RestaurantStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload restaurant profile image
  static Future<String> uploadRestaurantProfileImage(File imageFile, String restaurantId) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = RestaurantDatabaseStructure.getRestaurantImagePath(restaurantId, fileName);
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading restaurant profile image: $e');
      rethrow;
    }
  }

  /// Upload restaurant menu photo
  static Future<String> uploadRestaurantMenuPhoto(File imageFile, String restaurantId) async {
    try {
      final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = RestaurantDatabaseStructure.getRestaurantMenuImagePath(restaurantId, fileName);
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading restaurant menu photo: $e');
      rethrow;
    }
  }

  /// Upload restaurant promotional image
  static Future<String> uploadRestaurantPromotionalImage(File imageFile, String restaurantId) async {
    try {
      final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${RestaurantDatabaseStructure.restaurantPromotionalPath}/$restaurantId/$fileName';
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading restaurant promotional image: $e');
      rethrow;
    }
  }

  /// Upload restaurant document
  static Future<String> uploadRestaurantDocument(File documentFile, String restaurantId, String documentType) async {
    try {
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = '${RestaurantDatabaseStructure.restaurantDocumentsPath}/$restaurantId/$fileName';
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(documentFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading restaurant document: $e');
      rethrow;
    }
  }

  /// Delete restaurant image
  static Future<void> deleteRestaurantImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting restaurant image: $e');
      rethrow;
    }
  }

  /// Delete all restaurant images
  static Future<void> deleteAllRestaurantImages(String restaurantId) async {
    try {
      final imagePaths = [
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantMenuImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantPromotionalPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantDocumentsPath),
      ];

      for (final path in imagePaths) {
        try {
          final listResult = await _storage.ref().child(path).listAll();
          
          for (final item in listResult.items) {
            await item.delete();
          }
          
          for (final prefix in listResult.prefixes) {
            final subListResult = await prefix.listAll();
            for (final item in subListResult.items) {
              await item.delete();
            }
          }
        } catch (e) {
          print('Error deleting images from path $path: $e');
          // Continue with other paths even if one fails
        }
      }
    } catch (e) {
      print('Error deleting all restaurant images: $e');
      rethrow;
    }
  }

  /// Get restaurant storage usage
  static Future<Map<String, dynamic>> getRestaurantStorageUsage(String restaurantId) async {
    try {
      int totalSize = 0;
      int fileCount = 0;
      final Map<String, int> categorySizes = {};

      final imagePaths = [
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantMenuImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantPromotionalPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantDocumentsPath),
      ];

      for (final path in imagePaths) {
        try {
          final listResult = await _storage.ref().child(path).listAll();
          
          for (final item in listResult.items) {
            final metadata = await item.getMetadata();
            final size = metadata.size ?? 0;
            totalSize += size;
            fileCount++;
            
            final category = path.split('/').last;
            categorySizes[category] = (categorySizes[category] ?? 0) + size;
          }
          
          for (final prefix in listResult.prefixes) {
            final subListResult = await prefix.listAll();
            for (final item in subListResult.items) {
              final metadata = await item.getMetadata();
              final size = metadata.size ?? 0;
              totalSize += size;
              fileCount++;
              
              final category = path.split('/').last;
              categorySizes[category] = (categorySizes[category] ?? 0) + size;
            }
          }
        } catch (e) {
          print('Error getting storage usage for path $path: $e');
        }
      }

      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'categorySizes': categorySizes,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting restaurant storage usage: $e');
      return {
        'totalSize': 0,
        'fileCount': 0,
        'categorySizes': {},
        'totalSizeMB': '0.00',
      };
    }
  }

  /// Generate signed URL for restaurant image
  static Future<String> getRestaurantImageSignedUrl(String imageUrl, {Duration? expiration}) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting restaurant image signed URL: $e');
      rethrow;
    }
  }

  /// Upload multiple restaurant images
  static Future<List<String>> uploadMultipleRestaurantImages(
    List<File> imageFiles,
    String restaurantId,
    String category,
  ) async {
    try {
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = '${category}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        String storagePath;
        
        switch (category) {
          case 'menu':
            storagePath = RestaurantDatabaseStructure.getRestaurantMenuImagePath(restaurantId, fileName);
            break;
          case 'promo':
            storagePath = '${RestaurantDatabaseStructure.restaurantPromotionalPath}/$restaurantId/$fileName';
            break;
          default:
            storagePath = RestaurantDatabaseStructure.getRestaurantImagePath(restaurantId, fileName);
        }
        
        final ref = _storage.ref().child(storagePath);
        final uploadTask = ref.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        downloadUrls.add(downloadUrl);
      }
      
      return downloadUrls;
    } catch (e) {
      print('Error uploading multiple restaurant images: $e');
      rethrow;
    }
  }

  /// Clean up old restaurant images
  static Future<void> cleanupOldRestaurantImages(String restaurantId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final imagePaths = [
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantMenuImagesPath),
        RestaurantDatabaseStructure.getRestaurantStoragePath(restaurantId, RestaurantDatabaseStructure.restaurantPromotionalPath),
      ];

      for (final path in imagePaths) {
        try {
          final listResult = await _storage.ref().child(path).listAll();
          
          for (final item in listResult.items) {
            final metadata = await item.getMetadata();
            final created = metadata.timeCreated ?? DateTime.now();
            
            if (created.isBefore(cutoffDate)) {
              await item.delete();
            }
          }
        } catch (e) {
          print('Error cleaning up old images from path $path: $e');
        }
      }
    } catch (e) {
      print('Error cleaning up old restaurant images: $e');
    }
  }
}
