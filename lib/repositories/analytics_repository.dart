// 路径: (供应商 App) lib/repositories/analytics_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// --- ( ✨ 1. 更改导入 ✨ ) ---
// 我们不再需要 OrderModel, 我们需要 ReviewModel
import '../models/review.dart'; // <-- 确保你导入了 review.dart

class AnalyticsRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _vendorId => _auth.currentUser?.uid;

  // --- ( ✨ 2. 彻底替换这个函数 ✨ ) ---
  // (它现在返回 List<ReviewModel>)
  Stream<List<ReviewModel>> getVendorReviewsStream() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('reviews') // <-- ( ✨ 更改: 查询 'reviews' 集合 )
        .where('vendorId', isEqualTo: vendorId) // <-- ( ✨ 更改: 按 vendorId 过滤 )
        .orderBy('timestamp', descending: true) // <-- ( ✨ 更改: 按时间戳排序 )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(
              doc.data())) // <-- ( ✨ 更改: 使用 ReviewModel.fromMap )
          .toList();
    });
  }
}
