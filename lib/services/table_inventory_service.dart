import 'package:cloud_firestore/cloud_firestore.dart';

class TableInventoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String buildSlotKey(DateTime date, String timeHHmm) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    final String t = timeHHmm.replaceAll(':', '');
    return '${y}${m}${d}_${t}';
  }

  // Returns chosen capacity if successful; throws if none
  static Future<int> holdTable({
    required String restaurantId,
    required String slotKey,
    required int minGuests,
  }) async {
    final totalsRef = _firestore.collection('restaurants').doc(restaurantId).collection('table_totals').doc('base');
    final slotRef = _firestore.collection('restaurants').doc(restaurantId).collection('table_slots').doc(slotKey);

    return await _firestore.runTransaction<int>((tx) async {
      // Read totals
      final totalsSnap = await tx.get(totalsRef);
      if (!totalsSnap.exists) {
        throw Exception('Restaurant has not configured table capacities yet');
      }
      final Map<String, dynamic> totals = Map<String, dynamic>.from(totalsSnap.data() as Map<String, dynamic>);
      final Map<String, dynamic> totalMap = Map<String, dynamic>.from(totals['totals'] as Map<String, dynamic>);

      // Read or init slot
      final slotSnap = await tx.get(slotRef);
      Map<String, dynamic> availableMap;
      if (!slotSnap.exists) {
        availableMap = Map<String, dynamic>.from(totalMap);
      } else {
        final data = Map<String, dynamic>.from(slotSnap.data() as Map<String, dynamic>);
        availableMap = Map<String, dynamic>.from(data['available'] as Map<String, dynamic>);
      }

      // Find the smallest capacity >= minGuests with availability > 0
      final capacities = totalMap.keys.map((k) => int.parse(k)).toList()..sort();
      int? chosenCapacity;
      for (final cap in capacities) {
        if (cap >= minGuests) {
          final int avail = (availableMap['$cap'] as num?)?.toInt() ?? 0;
          if (avail > 0) {
            chosenCapacity = cap;
            break;
          }
        }
      }
      if (chosenCapacity == null) {
        throw Exception('No tables available for $minGuests guests');
      }

      // Decrement
      final int current = (availableMap['$chosenCapacity'] as num?)?.toInt() ?? 0;
      if (current <= 0) {
        throw Exception('No tables available for $minGuests guests');
      }
      availableMap['$chosenCapacity'] = current - 1;

      // Write slot doc
      tx.set(slotRef, {
        'available': availableMap,
        'totals': totalMap,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return chosenCapacity;
    });
  }

  static Future<void> releaseTable({
    required String restaurantId,
    required String slotKey,
    required int capacity,
  }) async {
    final slotRef = _firestore.collection('restaurants').doc(restaurantId).collection('table_slots').doc(slotKey);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(slotRef);
      if (!snap.exists) return; // nothing to do
      final data = Map<String, dynamic>.from(snap.data() as Map<String, dynamic>);
      final Map<String, dynamic> availableMap = Map<String, dynamic>.from(data['available'] as Map<String, dynamic>);
      final int current = (availableMap['$capacity'] as num?)?.toInt() ?? 0;
      availableMap['$capacity'] = current + 1;
      tx.update(slotRef, {
        'available': availableMap,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<Map<int, int>> watchAvailability({
    required String restaurantId,
    required String slotKey,
  }) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('table_slots')
        .doc(slotKey)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <int, int>{};
      final data = doc.data() as Map<String, dynamic>;
      final Map<String, dynamic> available = Map<String, dynamic>.from(data['available'] ?? {});
      return available.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    });
  }

  static Future<void> setTotals({
    required String restaurantId,
    required Map<int, int> totals,
  }) async {
    final totalsRef = _firestore.collection('restaurants').doc(restaurantId).collection('table_totals').doc('base');
    final Map<String, int> totalsStr = totals.map((k, v) => MapEntry(k.toString(), v));
    await totalsRef.set({
      'totals': totalsStr,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}


