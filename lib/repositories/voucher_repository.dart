import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voucher_model.dart';
import 'package:flutter/material.dart';

// Helper class to hold the voucher and its status
class VoucherEligibility {
  final VoucherModel voucher;
  final String eligibilityMessage;
  final bool isEligible;

  VoucherEligibility({
    required this.voucher,
    required this.eligibilityMessage,
    required this.isEligible,
  });
}


class VoucherRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all active, claimable vouchers.
  Future<List<VoucherModel>> fetchAllActiveVouchers() async {
    final now = DateTime.now();
    try {
      // This query requires the index on 'active', 'applicableOrderType', and 'endDate'
      final snapshot = await _db
          .collection('vouchers')
          .where('active', isEqualTo: true)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      final vouchers = snapshot.docs
          .map((doc) => VoucherModel.fromMap(doc.data(), doc.id))
          .where((voucher) =>
              voucher.startDate.isBefore(now) &&
              (voucher.totalRedemptions == 0 || 
               voucher.claimedRedemptions < voucher.totalRedemptions))
          .toList();

      return vouchers;
    } catch (e) {
      print("VoucherRepository Error fetching all vouchers: $e");
      if (e.toString().contains('FAILED_PRECONDITION')) {
         print("--- PLEASE CREATE THE FIRESTORE INDEX (see console error log for the link) ---");
      }
      return [];
    }
  }
  
  /// Checks all eligibility rules for a specific voucher and returns a status message.
  Future<String> getEligibilityStatus({
    required VoucherModel voucher, 
    required double subtotal, 
    required String currentOrderType, // 'pickup' or 'delivery'
    required List<String> cartVendorTypes, // ['Grocery', 'BlindBox']
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "Not logged in";

    // 1. Check Order Type (Pickup vs Delivery)
    if (voucher.applicableOrderType != 'all') {
      // This logic handles 'food_delivery' from your admin panel
      String voucherType = voucher.applicableOrderType == 'food_delivery' 
                           ? 'delivery' 
                           : voucher.applicableOrderType;
      if (voucherType != currentOrderType) {
        return voucherType == 'delivery' 
               ? "Delivery orders only" 
               : "Pickup orders only";
      }
    }

    // 2. Check Vendor Type (Grocery vs BlindBox)
    // THIS IS THE LOGIC THAT FIXES YOUR PROBLEM
    if (voucher.applicableVendorType != 'All') {
      if (voucher.applicableVendorType == 'Grocery' && !cartVendorTypes.contains('Grocery')) {
        return "Grocery items required";
      }
      if (voucher.applicableVendorType == 'BlindBox' && !cartVendorTypes.contains('BlindBox')) {
        return "BlindBox items required";
      }
    }

    // 3. Check Min Spend
    if (subtotal < voucher.minSpend) {
      return "Min. spend RM${voucher.minSpend.toStringAsFixed(2)}";
    }

    // 4. Check Weekend Only
    if (voucher.weekendOnly) {
      int weekday = DateTime.now().weekday; // Today is Saturday (6)
      if (weekday != DateTime.saturday && weekday != DateTime.sunday) {
        return "Weekend only"; 
      }
    }

    // 5. Check First Time Only
    if (voucher.firstTimeOnly) {
      try {
        final orderHistory = await _db
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
            
        if (orderHistory.docs.isNotEmpty) {
          return "First-time users only"; // User has ordered before
        }
      } catch (e) {
        print("Error checking user's first order: $e");
        return "Eligibility check failed"; // Fail safe
      }
    }
    
    // All checks passed
    return "Eligible";
  }


  /// Increments the claimedRedemptions count for a specific voucher.
  Future<void> incrementVoucherRedemption(String voucherId) async {
    try {
      await _db.collection('vouchers').doc(voucherId).update({
        'claimedRedemptions': FieldValue.increment(1),
      });
    } catch (e) {
      print("VoucherRepository Error updating redemption count for $voucherId: $e");
    }
  }
}