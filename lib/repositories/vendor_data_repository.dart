import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/vendor.dart';

// 一个简单的数据包，用于一次性传递两个模型
class VendorDataBundle {
  final UserModel user;
  final VendorModel vendor;
  VendorDataBundle({required this.user, required this.vendor});
}

class VendorDataRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --- 1. 一次性获取两个模型 ---
  Future<VendorDataBundle> getVendorData() async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');

    try {
      // 同时请求两个文档
      final userDocFuture = _db.collection('users').doc(uid).get();
      final vendorDocFuture = _db.collection('vendors').doc(uid).get();

      final results = await Future.wait([userDocFuture, vendorDocFuture]);

      final userDoc = results[0];
      final vendorDoc = results[1];

      if (!userDoc.exists || !vendorDoc.exists) {
        throw Exception('User or Vendor document not found.');
      }

      return VendorDataBundle(
        user: UserModel.fromMap(userDoc.data()!),
        vendor: VendorModel.fromMap(vendorDoc.data()!),
      );
    } catch (e) {
      print('Error fetching vendor data: $e');
      rethrow;
    }
  }

  // --- 2. 更新 UserModel ---
  Future<void> updateUser(UserModel user) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    await _db.collection('users').doc(uid).update(user.toMap());
  }

  // --- 3. 更新 VendorModel ---
  Future<void> updateVendor(VendorModel vendor) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    await _db.collection('vendors').doc(uid).update(vendor.toMap());
  }
}
