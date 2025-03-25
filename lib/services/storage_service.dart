import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadRestaurantImage(File imageFile, String restaurantId) async {
    try {
      // Create a unique file name using timestamp
      final String fileName = 'restaurant_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create a reference to the file location in Firebase Storage
      final Reference ref = _storage.ref().child('restaurants/$restaurantId/$fileName');
      
      // Upload the file
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Wait for the upload to complete and get the download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
} 