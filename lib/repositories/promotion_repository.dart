// 路径: lib/repositories/promotion_repository.dart
import 'dart:io'; // <-- ( ✨ 新增 ✨ )
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <-- ( ✨ 新增 ✨ )
import '../models/promotion.dart';

class PromotionRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // ( ✨ 新增 ✨ )
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _vendorId => _auth.currentUser?.uid;

  CollectionReference<PromotionModel> _getPromotionsRef() {
    // ... (不变)
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

  // --- ( ✨ 新增函数 ✨ ) ---
  // C - Create (创建促销 - 返回 ID)
  // 我们需要这个函数返回新创建的文档 ID，以便我们知道在哪里上传图片
  Future<String> addPromotion(PromotionModel promo) async {
    try {
      final docRef = await _getPromotionsRef().add(promo);
      return docRef.id; // 返回新的 ID
    } catch (e) {
      print('Error adding promotion: $e');
      rethrow;
    }
  }

  // R - Read (读取促销流) (不变)
  Stream<List<PromotionModel>> getPromotionsStream() {
    // ... (不变)
    return _getPromotionsRef()
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // U - Update (更新促销) (不变)
  Future<void> updatePromotion(PromotionModel promo) async {
    // ... (不变)
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

  // D - Delete (删除促销) (不变)
  Future<void> deletePromotion(String promoId) async {
    // ... (不变)
  }

  // --- ( ✨ 新增函数：上传横幅图片 ✨ ) ---
  Future<String> uploadBannerImage(File imageFile, String promoId) async {
    try {
      final vendorId = _vendorId;
      if (vendorId == null) throw Exception('User not logged in');

      // 路径: /promotions/<vendor_id>/<promo_id>.jpg
      final ref =
          _storage.ref('promotions').child(vendorId).child('$promoId.jpg');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading banner image: $e');
      rethrow;
    }
  }

  // --- ( ✨ 新增函数：仅更新 URL ✨ ) ---
  // 用于在图片上传后更新文档
  Future<void> updatePromotionBannerUrl(String promoId, String url) async {
    try {
      await _getPromotionsRef().doc(promoId).update({'bannerUrl': url});
    } catch (e) {
      print('Error updating banner URL: $e');
      rethrow;
    }
  }
}