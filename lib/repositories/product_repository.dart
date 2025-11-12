import 'dart:io'; // 用于图片上传
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart'; // 导入你的新模型

class ProductRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 获取当前供应商的 UID
  String? get _vendorId => _auth.currentUser?.uid;

  // 获取供应商的产品集合引用
  CollectionReference<Product> _getProductsRef() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('products')
        .withConverter<Product>(
          fromFirestore: (snapshot, _) =>
              Product.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (product, _) => product.toMap(),
        );
  }

  // C - Create (创建产品)
  Future<DocumentReference<Product>> addProduct(Product product) async {
    try {
      return await _getProductsRef().add(product);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // R - Read (读取产品流)
  Stream<List<Product>> getProductsStream() {
    return _getProductsRef().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // U - Update (更新产品)
  Future<void> updateProduct(Product product) async {
    if (product.id == null) {
      throw Exception('Product ID is required for updates');
    }
    try {
      await _getProductsRef().doc(product.id).update(product.toMap());
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // D - Delete (删除产品)
  Future<void> deleteProduct(String productId) async {
    try {
      await _getProductsRef().doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // --- (附加) Firebase Storage 图片上传 ---
  Future<String> uploadProductImage(File imageFile, String productId) async {
    try {
      final vendorId = _vendorId;
      // 路径: /products/<vendor_id>/<product_id>.jpg
      final ref = FirebaseStorage.instance
          .ref('products')
          .child(vendorId!)
          .child('$productId.jpg');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}
