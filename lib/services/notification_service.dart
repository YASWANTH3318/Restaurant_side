import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../utils/date_format_util.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _notificationsCollection =
      _firestore.collection('notifications');

  // Get all notifications for a user
  static Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Get unread notifications count for a user
  static Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // Mark a notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Create a new notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': data,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications for a user
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Create a like notification
  static Future<void> createLikeNotification({
    required String userId,
    required String likerName,
    required String postTitle,
    required String postId,
    required String likerId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Like',
      body: '$likerName liked your post "$postTitle"',
      type: 'like',
      data: {
        'postId': postId,
        'likerId': likerId,
      },
    );
  }

  // Create a follower notification
  static Future<void> createFollowerNotification({
    required String userId,
    required String followerName,
    required String followerId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Follower',
      body: '$followerName started following you',
      type: 'follower',
      data: {
        'followerId': followerId,
      },
    );
  }

  // Create a comment notification
  static Future<void> createCommentNotification({
    required String userId,
    required String commenterName,
    required String postTitle,
    required String postId,
    required String commentId,
    required String commentText,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Comment',
      body: '$commenterName commented on your post: "$commentText"',
      type: 'comment',
      data: {
        'postId': postId,
        'commentId': commentId,
      },
    );
  }

  // Create a booking notification
  static Future<void> createBookingNotification({
    required String userId,
    required String restaurantName,
    required String bookingId,
    required String restaurantId,
    required DateTime bookingTime,
    required int guestCount,
  }) async {
    // Use utility class for consistent formatting
    final formattedDate = DateFormatUtil.formatDateIndian(bookingTime);
    final formattedTime = DateFormatUtil.formatTimeIndian(bookingTime);
    
    await createNotification(
      userId: userId,
      title: 'Booking Confirmed',
      body: 'Your table for $guestCount at $restaurantName on $formattedDate at $formattedTime has been confirmed',
      type: 'booking',
      data: {
        'bookingId': bookingId,
        'restaurantId': restaurantId,
        'bookingTime': bookingTime.millisecondsSinceEpoch,
        'guestCount': guestCount,
      },
    );
  }

  // Create a share notification
  static Future<void> createShareNotification({
    required String userId,
    required String contentTitle,
    required String contentType,
    required String contentId,
    required int shareCount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Content Shared',
      body: 'Your $contentType "$contentTitle" was shared $shareCount times',
      type: 'share',
      data: {
        '${contentType}Id': contentId,
        'shareCount': shareCount,
      },
    );
  }
} 