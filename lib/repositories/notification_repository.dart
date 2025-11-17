import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart'; // 导入我们刚创建的模型

class NotificationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --- FIX: Correctly defined return type for the unread count stream ---
  Stream<int> getUnreadNotificationCountStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false) // ( ✨ 关键查询 ✨ )
        .snapshots() // 监听变化
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // (这是我们稍后在 notifications_page.dart 中需要的函数)
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