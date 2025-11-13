import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/promotion.dart'; // 导入我们的新模型

class PromotionRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 获取当前供应商的 UID
  String? get _vendorId => _auth.currentUser?.uid;

  // 获取供应商的 "promotions" 子集合引用
  CollectionReference<PromotionModel> _getPromotionsRef() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('promotions')
        .withConverter<PromotionModel>(
          fromFirestore: (snapshot, _) =>
              PromotionModel.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (promo, _) => promo.toMap(),
        );
  }

  // C - Create (创建促销)
  Future<void> addPromotion(PromotionModel promo) async {
    try {
      await _getPromotionsRef().add(promo);
    } catch (e) {
      print('Error adding promotion: $e');
      rethrow;
    }
  }

  // R - Read (读取促销流)
  // 此函数现在只获取尚未过期的促销活动
  Stream<List<PromotionModel>> getPromotionsStream() {
    return _getPromotionsRef()
        // 只获取在今天或之后结束的促销
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
      // (我们在 marketing_page.dart 中处理 'active'/'expired' 逻辑)
    });
  }

  // U - Update (更新促销)
  Future<void> updatePromotion(PromotionModel promo) async {
    if (promo.id == null) {
      throw Exception('Promotion ID is required for updates');
    }
    try {
      await _getPromotionsRef().doc(promo.id).update(promo.toMap());
    } catch (e) {
      print('Error updating promotion: $e');
      rethrow;
    }
  }

  // D - Delete (删除促销)
  Future<void> deletePromotion(String promoId) async {
    try {
      await _getPromotionsRef().doc(promoId).delete();
    } catch (e) {
      print('Error deleting promotion: $e');
      rethrow;
    }
  }

  // TODO: 你还需要一个 Firebase Storage 的 uploadBannerImage 函数
}
