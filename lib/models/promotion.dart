import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String? id; // 文档 ID
  final String title;
  final String bannerUrl; // 促销横幅图片
  final String productType; // 'Blindbox' 或 'Grocery'
  final DateTime startDate;
  final DateTime endDate;
  final int discountPercentage; // e.g., 20 (代表 20%)
  final int totalRedemptions; // 总共可以被兑换的次数
  final int claimedRedemptions; // 已经被兑换的次数

  PromotionModel({
    this.id,
    required this.title,
    this.bannerUrl = '',
    required this.productType,
    required this.startDate,
    required this.endDate,
    required this.discountPercentage,
    required this.totalRedemptions,
    this.claimedRedemptions = 0, // 默认为 0
  });

  // 从 Firestore 转换
  factory PromotionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PromotionModel(
      id: documentId,
      title: map['title'] ?? '',
      bannerUrl: map['bannerUrl'] ?? '',
      productType: map['productType'] ?? 'Grocery',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      discountPercentage: map['discountPercentage'] ?? 0,
      totalRedemptions: map['totalRedemptions'] ?? 0,
      claimedRedemptions: map['claimedRedemptions'] ?? 0,
    );
  }

  // 转换到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'bannerUrl': bannerUrl,
      'productType': productType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'discountPercentage': discountPercentage,
      'totalRedemptions': totalRedemptions,
      'claimedRedemptions': claimedRedemptions,
    };
  }

  // CopyWith 帮助我们更新 edit 页面
  PromotionModel copyWith({
    String? id,
    String? title,
    String? bannerUrl,
    String? productType,
    DateTime? startDate,
    DateTime? endDate,
    int? discountPercentage,
    int? totalRedemptions,
    int? claimedRedemptions,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      productType: productType ?? this.productType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      totalRedemptions: totalRedemptions ?? this.totalRedemptions,
      claimedRedemptions: claimedRedemptions ?? this.claimedRedemptions,
    );
  }
}
