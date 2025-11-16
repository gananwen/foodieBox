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

  Future<void> updateStoreHours(List<String> newHours) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in.');
    }

    try {
      // Update the 'storeHours' field in the 'vendors' document
      await _db.collection('vendors').doc(uid).update({
        'storeHours': newHours,
      });
    } catch (e) {
      print('Error updating store hours: $e');
      rethrow;
    }
  }

  Future<void> deleteVendorAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }
    final uid = user.uid;
    final email = user.email;

    if (email == null) {
      throw Exception('User has no email for re-authentication.');
    }

    try {
      // 1. Re-authenticate the user to confirm their identity
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // --- Deletion Process Starts ---

      // 2. Delete all subcollections (Products)
      // We do this in batches to avoid memory issues if there are many products
      final productsRef =
          _db.collection('vendors').doc(uid).collection('products');
      await _deleteSubcollection(productsRef);

      // 3. Delete all subcollections (Promotions)
      final promosRef =
          _db.collection('vendors').doc(uid).collection('promotions');
      await _deleteSubcollection(promosRef);

      // 4. Delete the main 'vendors' and 'users' documents
      WriteBatch mainDocBatch = _db.batch();
      mainDocBatch.delete(_db.collection('vendors').doc(uid));
      mainDocBatch.delete(_db.collection('users').doc(uid));
      await mainDocBatch.commit();

      // 5. Delete the Auth user (This is the very last step)
      await user.delete();
    } on FirebaseAuthException {
      // Re-throw auth exceptions (like 'wrong-password')
      // so the UI can catch them and display a specific message.
      rethrow;
    } catch (e) {
      // Catch other errors
      print('Error during account deletion: $e');
      throw Exception('An error occurred during account deletion.');
    }
  }

  // ( ✨ ADD THIS HELPER FUNCTION ✨ )
  // This helper deletes all documents in a subcollection.
  Future<void> _deleteSubcollection(CollectionReference collectionRef) async {
    QuerySnapshot snapshot = await collectionRef.limit(50).get();
    while (snapshot.docs.isNotEmpty) {
      WriteBatch batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Get the next batch
      snapshot = await collectionRef.limit(50).get();
    }
  }
}
