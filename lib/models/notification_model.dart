import 'package:cloud_firestore/cloud_firestore.dart';

// (我们沿用你之前的枚举，但现在它在自己的模型文件中)
enum NotificationType { order, offer, update, product, redeem }

class AppNotification {
  final String id;
  final String userId; // ( ✨ 关键 ✨ ) 这个通知属于哪个用户
  final String title;
  final String body;
  final String type; // 'order', 'offer', 'product', 'redeem'
  final Timestamp timestamp;
  bool isRead;
  final String? orderId; // <-- FIXED: Added missing orderId field

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.orderId, // <-- ADDED TO CONSTRUCTOR
  });

  // 从 Firestore 转换
  factory AppNotification.fromMap(Map<String, dynamic> map, String documentId) {
    return AppNotification(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'update',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      orderId: map['orderId'], // <-- MAPPED HERE
    );
  }

  // 转换到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp,
      'isRead': isRead,
      'orderId': orderId, // <-- MAPPED HERE
    };
  }
}