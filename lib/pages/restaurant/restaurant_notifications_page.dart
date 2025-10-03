import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/date_format_util.dart';

class RestaurantNotificationsPage extends StatefulWidget {
  const RestaurantNotificationsPage({super.key});

  @override
  State<RestaurantNotificationsPage> createState() => _RestaurantNotificationsPageState();
}

class _RestaurantNotificationsPageState extends State<RestaurantNotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _auth.currentUser == null
                ? const Stream.empty()
                : _firestore
                    .collection('restaurants')
                    .doc(_auth.currentUser!.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              if (unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: _markAllAsRead,
                  tooltip: 'Mark all as read',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _auth.currentUser == null
            ? const Stream.empty()
            : _firestore
                .collection('restaurants')
                .doc(_auth.currentUser!.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications received',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see table reservation requests here',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data();
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? 'reservation';
              final title = data['title'] ?? 'New Notification';
              final message = data['message'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final reservationData = data['reservationData'] as Map<String, dynamic>?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRead ? Colors.grey[300]! : Colors.blue[200]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _handleNotificationTap(doc.id, data),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getNotificationIcon(type),
                                color: _getNotificationColor(type),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                      fontSize: 16,
                                      color: isRead ? Colors.grey[800] : Colors.blue[800],
                                    ),
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormatUtil.formatRelativeTime(createdAt.toDate()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        if (reservationData != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reservation Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildReservationDetail('Customer', reservationData['customerName'] ?? 'Unknown'),
                                _buildReservationDetail('Date', _formatDate(reservationData['reservationDate'])),
                                _buildReservationDetail('Time', reservationData['reservationTime'] ?? ''),
                                _buildReservationDetail('Guests', '${reservationData['numberOfGuests'] ?? 0}'),
                                if (reservationData['specialRequests'] != null && 
                                    reservationData['specialRequests'].toString().isNotEmpty)
                                  _buildReservationDetail('Special Requests', reservationData['specialRequests']),
                              ],
                            ),
                          ),
                        ],
                        if (type == 'reservation' && !isRead) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _handleReservationAction(doc.id, 'rejected'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _handleReservationAction(doc.id, 'accepted'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      return DateFormatUtil.formatDateIndian(date.toDate());
    }
    return date.toString();
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'reservation':
        return Icons.table_restaurant;
      case 'order':
        return Icons.receipt_long;
      case 'review':
        return Icons.star;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'reservation':
        return Colors.green;
      case 'order':
        return Colors.blue;
      case 'review':
        return Colors.amber;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleNotificationTap(String notificationId, Map<String, dynamic> data) async {
    try {
      // Mark notification as read
      await _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // If it's a reservation notification, you could navigate to orders page
      if (data['type'] == 'reservation') {
        // Navigate to orders page or show reservation details
        Navigator.pop(context); // Go back to previous page
        // You could add navigation to orders page here if needed
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  Future<void> _handleReservationAction(String notificationId, String action) async {
    try {
      // Get the notification data
      final notificationDoc = await _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) return;

      final notificationData = notificationDoc.data()!;
      final reservationData = notificationData['reservationData'] as Map<String, dynamic>?;

      if (reservationData == null) return;

      // Update the reservation status in the reservations collection
      final reservationId = reservationData['id'];
      if (reservationId != null) {
        await _firestore
            .collection('reservations')
            .doc(reservationId)
            .update({
          'status': action,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Mark notification as read
      await _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'actionTaken': action,
        'actionTakenAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation ${action == 'accepted' ? 'accepted' : 'rejected'} successfully'),
            backgroundColor: action == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error handling reservation action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action == 'accepted' ? 'accept' : 'reject'} reservation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notifications as read')),
        );
      }
    }
  }
}
