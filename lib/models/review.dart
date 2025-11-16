import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String vendorId;
  final String userId;
  final double rating;
  final String reviewText;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.userId,
    required this.rating,
    required this.reviewText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap({String? newId}) {
    return {
      'id': newId ?? id,
      'orderId': orderId,
      'vendorId': vendorId,
      'userId': userId,
      'rating': rating,
      'reviewText': reviewText,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      userId: map['userId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: map['reviewText'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}