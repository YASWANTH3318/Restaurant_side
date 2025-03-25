import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String houseNumber;
  final String houseName;
  final String landmark;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.houseNumber,
    required this.houseName,
    required this.landmark,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'houseNumber': houseNumber,
      'houseName': houseName,
      'landmark': landmark,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      userId: map['userId'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      houseName: map['houseName'] ?? '',
      landmark: map['landmark'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? houseNumber,
    String? houseName,
    String? landmark,
    String? street,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      houseNumber: houseNumber ?? this.houseNumber,
      houseName: houseName ?? this.houseName,
      landmark: landmark ?? this.landmark,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 