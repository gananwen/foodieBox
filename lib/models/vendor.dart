import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String uid;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String vendorType;
  final String businessPhotoUrl;
  final String businessLicenseUrl;
  final String halalCertificateUrl;
  final bool isApproved;
  final double rating;
  final List<String> storeHours;
  final bool hasExpiryDeals;
  final int reviewCount;

  VendorModel({
    required this.uid,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.vendorType,
    required this.businessPhotoUrl,
    required this.businessLicenseUrl,
    this.halalCertificateUrl = '',
    this.isApproved = false,
    this.rating = 0.0,
    this.storeHours = const [],
    this.hasExpiryDeals = false, // Default to false
    this.reviewCount = 0,
  });

  // 从 Firestore (Map) 转换
  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      uid: map['uid'] ?? '',
      storeName: map['storeName'] ?? '',
      storeAddress: map['storeAddress'] ?? '',
      storePhone: map['storePhone'] ?? '',
      vendorType: map['vendorType'] ?? 'Grocery', // <-- (添加了默认值)
      businessPhotoUrl: map['businessPhotoUrl'] ??
          'https://placehold.co/600x400/FFF8E1/E6A000?text=Store',
      businessLicenseUrl: map['businessLicenseUrl'] ?? '',
      halalCertificateUrl: map['halalCertificateUrl'] ?? '',
      isApproved: map['isApproved'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0, // <-- (FIXED)
      storeHours: List<String>.from(map['storeHours'] ?? []),
      hasExpiryDeals: map['hasExpiryDeals'] ?? false,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0, // <-- (FIXED)
    );
  }

  // 转换到 Map (用于写入 Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'vendorType': vendorType, // <-- (添加)
      'businessPhotoUrl': businessPhotoUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'halalCertificateUrl': halalCertificateUrl,
      'isApproved': isApproved,
      'rating': rating,
      'storeHours': storeHours,
      'hasExpiryDeals': hasExpiryDeals,
      'reviewCount': reviewCount, // <-- (ADDED)
    };
  }

  // --- (FIX) 这就是你缺少的另一个方法 ---
  VendorModel copyWith({
    String? uid,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? vendorType,
    String? businessPhotoUrl,
    String? businessLicenseUrl,
    String? halalCertificateUrl,
    bool? isApproved,
    double? rating,
    List<String>? storeHours,
    bool? hasExpiryDeals,
    int? reviewCount, // <-- (FIXED)
  }) {
    return VendorModel(
      uid: uid ?? this.uid,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      vendorType: vendorType ?? this.vendorType,
      businessPhotoUrl: businessPhotoUrl ?? this.businessPhotoUrl,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      halalCertificateUrl: halalCertificateUrl ?? this.halalCertificateUrl,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      storeHours: storeHours ?? this.storeHours,
      hasExpiryDeals: hasExpiryDeals ?? this.hasExpiryDeals,
      reviewCount: reviewCount ?? this.reviewCount, // <-- (FIXED)
    );
  }
}
