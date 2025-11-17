// 路径: lib/repositories/feedback_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> submitFeedback(
      {required String message, required String role}) async {
    final uid = _uid;
    if (uid == null) throw Exception("User not logged in");

    try {
      // 将反馈保存到一个新的 'feedback' 根集合中
      await _db.collection('feedback').add({
        'message': message,
        'userId': uid,
        'role': role, // 存储是 'User' 还是 'Vendor'
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'New', // 供您的 Admin 仪表板跟踪
      });
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }
}
