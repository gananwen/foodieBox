import 'package:cloud_firestore/cloud_firestore.dart';

/// A model for Vouchers, which are distinct from Promotions.
/// Vouchers are fetched from the 'vouchers' collection.
class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String type; // 'delivery', 'pickup', or 'all'
  final double minSpend;
  final double discountAmount; // For fixed RM discounts
  final double discountPercentage; // For % discounts
  final DateTime startDate;
  final DateTime endDate;
  final int totalRedemptions;
  final int claimedRedemptions;

  VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.minSpend,
    required this.discountAmount,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.totalRedemptions,
    required this.claimedRedemptions,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return VoucherModel(
      id: id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'all',
      minSpend: (map['minSpend'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalRedemptions: map['totalRedemptions'] ?? 0,
      claimedRedemptions: map['claimedRedemptions'] ?? 0,
    );
  }

  /// Calculates the discount based on a subtotal.
  /// Returns 0.0 if minSpend is not met.
  double calculateDiscount(double subtotal) {
    if (subtotal < minSpend) {
      return 0.0;
    }

    double discount = 0.0;
    if (discountPercentage > 0) {
      // Handle percentage discount
      discount = subtotal * (discountPercentage / 100);
    } else if (discountAmount > 0) {
      // Handle fixed amount discount
      discount = discountAmount;
    }

    // You could add a 'maxDiscountCap' field to the model
    // and check it here if needed.
    // if (maxDiscountCap != null && discount > maxDiscountCap) {
    //   discount = maxDiscountCap;
    // }

    return discount;
  }

  /// Returns a string describing the discount, e.g., "30% OFF" or "RM10 OFF"
  String get discountLabel {
    if (discountPercentage > 0) {
      // Use .toInt() to avoid ".0%"
      return '${discountPercentage.toInt()}% OFF';
    } else if (discountAmount > 0) {
      return 'RM${discountAmount.toStringAsFixed(2)} OFF';
    }
    return 'Voucher';
  }
}