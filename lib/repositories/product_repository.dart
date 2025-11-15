import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';

class ProductRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _vendorId => _auth.currentUser?.uid;

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

  Future<DocumentReference<Product>> addProduct(Product product) async {
    // ... (此函数不变) ...
    try {
      return await _getProductsRef().add(product);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // --- ( ✨ 关键修改 ✨ ) ---
  // R - Read (读取产品流)
  // 我们现在要求传入 'vendorType'
  Stream<List<Product>> getProductsStream(String vendorType) {
    // 1. 添加一个新的 .where() 子句来过滤 productType
    return _getProductsRef()
        .where('productType', isEqualTo: vendorType)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
  // --- ( ✨ 结束修改 ✨ ) ---

  Future<void> updateProduct(Product product) async {
    // ... (此函数不变) ...
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

  Future<void> deleteProduct(String productId) async {
    // ... (此函数不变) ...
    try {
      await _getProductsRef().doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<String> uploadProductImage(File imageFile, String productId) async {
    // ... (此函数不变) ...
    try {
      final vendorId = _vendorId;
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
