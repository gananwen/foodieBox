import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/review.dart';

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // This is the main function that does two things:
  // 1. Saves the new review
  // 2. Updates the vendor's average rating in a transaction
  Future<void> addReviewAndUpdateVendor(ReviewModel review) async {
    // 1. Add the new review to the 'reviews' collection
    final reviewRef = _db.collection('reviews').doc();
    await reviewRef.set(review.toMap(newId: reviewRef.id));

    // 2. Update the associated order
    await _db.collection('orders').doc(review.orderId).update({
      'hasBeenReviewed': true,
      'rating': review.rating,
      'reviewText': review.reviewText,
    });

    // 3. Update the vendor's average rating using a transaction
    final vendorRef = _db.collection('vendors').doc(review.vendorId);

    return _db.runTransaction((transaction) async {
      final vendorSnapshot = await transaction.get(vendorRef);

      if (!vendorSnapshot.exists) {
        throw Exception("Vendor not found!");
      }

      // Get current rating data
      final data = vendorSnapshot.data() as Map<String, dynamic>;
      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

      // Calculate new average
      final double newAverageRating =
          ((currentRating * reviewCount) + review.rating) / (reviewCount + 1);
      final int newReviewCount = reviewCount + 1;

      // Set the new data back
      transaction.update(vendorRef, {
        'rating': newAverageRating,
        'reviewCount': newReviewCount,
      });
    });
  }

  // Stream to get all reviews for a specific vendor
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