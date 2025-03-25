import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all addresses for a user
  static Future<List<AddressModel>> getUserAddresses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting addresses: $e');
      return [];
    }
  }

  // Add a new address
  static Future<String?> addAddress(AddressModel address) async {
    try {
      // If this is the first address or marked as default, unset other default addresses
      if (address.isDefault) {
        await _unsetOtherDefaultAddresses(address.userId);
      }

      final docRef = await _firestore
          .collection('users')
          .doc(address.userId)
          .collection('addresses')
          .add(address.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }

  // Update an existing address
  static Future<bool> updateAddress(AddressModel address) async {
    try {
      // If this address is being set as default, unset other default addresses
      if (address.isDefault) {
        await _unsetOtherDefaultAddresses(address.userId, excludeId: address.id);
      }

      await _firestore
          .collection('users')
          .doc(address.userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());

      return true;
    } catch (e) {
      print('Error updating address: $e');
      return false;
    }
  }

  // Delete an address
  static Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // Set an address as default
  static Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
      await _unsetOtherDefaultAddresses(userId);
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});

      return true;
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }

  // Helper method to unset other default addresses
  static Future<void> _unsetOtherDefaultAddresses(String userId, {String? excludeId}) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    for (var doc in querySnapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      await doc.reference.update({'isDefault': false});
    }
  }
} 