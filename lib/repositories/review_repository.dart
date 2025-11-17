import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/review.dart';

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Adds a review, updates the order, and updates the vendor rating safely.
  Future<void> addReviewAndUpdateVendor(ReviewModel review) async {
    // 1. Add the review to the 'reviews' collection
    final reviewRef = _db.collection('reviews').doc();
    await reviewRef.set(review.toMap(newId: reviewRef.id));

    // 2. Update the associated order (only allowed fields!)
    //
    // ⚠️ --- FIX --- ⚠️
    // Added 'reviewTimestamp' to match the security rule in firestore.rules.
    // This was the cause of the permission error.
    await _db.collection('orders').doc(review.orderId).update({
      'hasBeenReviewed': true,
      'rating': review.rating,
      'reviewText': review.reviewText,
      'reviewTimestamp': review.timestamp, // <-- ADDED THIS LINE
    });
    // ⚠️ --- END FIX --- ⚠️

    // 3. Update the vendor's average rating using a transaction
    //
    // ❗️ --- CRITICAL SECURITY WARNING --- ❗️
    // This logic is highly insecure. Your security rules are allowing
    // this client-side code to run, which means ANY user can
    // potentially manipulate a vendor's rating.
    // This entire transaction block should be REMOVED from the client
    // and moved into a Cloud Function that triggers when a document
    // is created in the 'reviews' collection.
    //
    final vendorRef = _db.collection('vendors').doc(review.vendorId);
    await _db.runTransaction((transaction) async {
      final vendorSnapshot = await transaction.get(vendorRef);

      if (!vendorSnapshot.exists) {
        throw Exception("Vendor not found!");
      }

      final data = vendorSnapshot.data() as Map<String, dynamic>;

      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

      // Calculate new average
      final double newAverageRating =
          ((currentRating * reviewCount) + review.rating) / (reviewCount + 1);
      final int newReviewCount = reviewCount + 1;

      // Update vendor
      transaction.update(vendorRef, {
        'rating': newAverageRating,
        'reviewCount': newReviewCount,
      });
    });
  }

  /// Stream to get all reviews for a specific vendor
  Stream<List<ReviewModel>> getReviewsForVendor(String vendorId) {
    return _db
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data()))
            .toList());
  }
}