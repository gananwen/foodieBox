import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherModel {
  final String id;
  final String title; // 'name' from admin form
  final String code;
  final String description;
  final String applicableOrderType; // 'all', 'pickup', 'food_delivery'
  final String applicableVendorType; // 'All', 'Grocery', 'BlindBox'

  final String discountType; // 'percentage' or 'fixed'
  final double discountAmount;
  final double discountPercentage;
  
  final double minSpend;
  final bool firstTimeOnly;
  final bool weekendOnly;
  final bool freeDelivery;
  final bool active;

  final DateTime startDate;
  final DateTime endDate;
  final int totalRedemptions; 
  final int claimedRedemptions; 

  VoucherModel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.applicableOrderType,
    required this.applicableVendorType, // --- NEW ---
    required this.discountType,
    required this.discountAmount,
    required this.discountPercentage,
    required this.minSpend,
    required this.firstTimeOnly,
    required this.weekendOnly,
    required this.freeDelivery,
    required this.active,
    required this.startDate,
    required this.endDate,
    this.totalRedemptions = 1000, 
    this.claimedRedemptions = 0, 
  });

  factory VoucherModel.fromMap(Map<String, dynamic> map, String id) {
    String discountType = map['discountType'] ?? 'percentage';
    double discountValue = (map['discountValue'] ?? 0.0).toDouble();
    double discountAmount = 0.0;
    double discountPercentage = 0.0;

    if (discountType == 'fixed') {
      discountAmount = discountValue;
    } else {
      discountPercentage = discountValue;
    }

    String orderType = map['applicableOrderType'] ?? 'all';
    if (orderType == "") {
      orderType = 'all'; // Handle empty string from admin panel
    }

    return VoucherModel(
      id: id,
      title: map['name'] ?? '', // Use 'name' from admin form
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      applicableOrderType: orderType,
      
      // --- THIS LINE READS THE VENDOR TYPE ---
      applicableVendorType: map['applicableVendorType'] ?? 'All', 
      
      discountType: discountType,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      minSpend: (map['minSpend'] ?? 0.0).toDouble(),
      firstTimeOnly: map['firstTimeOnly'] ?? false,
      weekendOnly: map['weekendOnly'] ?? false,
      freeDelivery: map['freeDelivery'] ?? false,
      active: map['active'] ?? true,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      totalRedemptions: map['totalRedemptions'] ?? 1000,
      claimedRedemptions: map['claimedRedemptions'] ?? 0,
    );
  }

  /// Calculates the discount based on a subtotal.
  double calculateDiscount(double subtotal) {
    if (subtotal < minSpend) {
      return 0.0;
    }
    double discount = 0.0;
    if (discountPercentage > 0) {
      discount = subtotal * (discountPercentage / 100);
    } else if (discountAmount > 0) {
      discount = discountAmount;
    }
    return discount;
  }

  /// Returns a string describing the discount, e.g., "10% OFF" or "RM5 OFF"
  String get discountLabel {
    if (discountPercentage > 0) {
      return '${discountPercentage.toInt()}% OFF';
    } else if (discountAmount > 0) {
      return 'RM${discountAmount.toStringAsFixed(2)} OFF';
    }
    return 'Voucher';
  }
}