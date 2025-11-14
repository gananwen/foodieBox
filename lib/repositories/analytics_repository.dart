// 路径: lib/repositories/analytics_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart'; // 确保 import 路径正确

class AnalyticsRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _vendorId => _auth.currentUser?.uid;

  // 获取所有 "已完成" 且 "已评价" 的订单
  Stream<List<OrderModel>> getVendorReviewsStream() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId)
        .where('status', isEqualTo: 'Completed')
        .where('rating', isGreaterThan: 0) // 假设所有评分都 > 0
        .orderBy('rating', descending: true) // 先按评分排
        .orderBy('reviewTimestamp', descending: true) // 再按时间排
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()!, doc.id))
          .toList();
    });
  }
}
