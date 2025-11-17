import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart'; 

class NotificationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --- CRITICAL: Function to send notification on status change ---
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String newStatus,
    required String vendorName,
  }) async {
    final String title;
    final String body;
    final String type = 'order'; // Always 'order' type for status updates

    switch (newStatus.toLowerCase()) {
      case 'received':
        title = 'Order Accepted! Starting Preparation';
        body = 'The vendor $vendorName has received and accepted your order #$orderId.';
        break;
      case 'rejected':
        title = 'Order Declined';
        body = 'Your payment for order #$orderId was declined by the Admin. Check your payment proof.';
        break;
      case 'preparing':
        title = 'Order Preparation Underway';
        body = 'The vendor $vendorName is preparing your items.';
        break;
      case 'ready for pickup':
        title = 'Ready for Pickup!';
        body = 'Your BlindBox order #$orderId is ready for collection at $vendorName.';
        break;
      case 'delivering':
        title = 'Out for Delivery!';
        body = 'Your order #$orderId is now with the driver and is on its way.';
        break;
      default:
        // Skip notification for minor or unknown statuses
        return;
    }

    final newNotification = AppNotification(
      id: '', // Firestore will assign ID
      userId: userId,
      title: title,
      body: body,
      type: type,
      timestamp: Timestamp.now(),
      isRead: false,
      orderId: orderId, // <-- FIX: This line now matches the AppNotification constructor
    );

    try {
      await _db.collection('notifications').add(newNotification.toMap());
    } catch (e) {
      print("Error sending status notification: $e");
    }
  }
  // --- END CRITICAL FUNCTION ---

  // --- FIX: Correctly defined return type for the unread count stream ---
  Stream<int> getUnreadNotificationCountStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots() 
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // (This streams the list for the notifications page)
  Stream<List<AppNotification>> getNotificationsStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // (用于点击通知时)
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking as read: $e');
      rethrow;
    }
  }
  
  // --- FIX: Added the missing markAllAsRead method using a batch ---
  Future<void> markAllAsRead(List<AppNotification> notifications) async {
    final batch = _db.batch();
    
    // Only update those that are not already read
    for (var notification in notifications.where((n) => !n.isRead)) {
      final docRef = _db.collection('notifications').doc(notification.id);
      batch.update(docRef, {'isRead': true});
    }
    await batch.commit();
  }
}