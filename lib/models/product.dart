import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id; // 文档 ID
  final String title;
  final String description;
  final String productType; // 'Blind Box' 或 'Grocery Deal'
  
  // --- NEW FIELDS ---
  // You MUST add these to your Firebase data
  // e.g., category: "Frozen", subCategory: "Ice Cream"
  final String category;
  final String subCategory;
  // --- END NEW FIELDS ---

  final String expiryDate;
  final double originalPrice;
  final double discountedPrice;
  final String imageUrl;
  final int quantity;
  final bool isHalal;
  final bool isVegan;
  final bool isNoPork;

  Product({
    this.id,
    required this.title,
    required this.description,
    required this.productType,
    required this.category,     // NEW
    required this.subCategory, // NEW
    required this.expiryDate,
    required this.originalPrice,
    required this.discountedPrice,
    required this.imageUrl,
    required this.quantity,
    required this.isHalal,
    required this.isVegan,
    required this.isNoPork,
  });

  // 将 Product 对象转换为 Map (用于写入 Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'productType': productType,
      'category': category,     // NEW
      'subCategory': subCategory, // NEW
      'expiryDate': expiryDate,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isHalal': isHalal,
      'isVegan': isVegan,
      'isNoPork': isNoPork,
    };
  }

  // 从 Firestore快照 (Map) 创建 Product 对象
  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      productType: map['productType'] ?? 'Grocery Deal',
      category: map['category'] ?? '',     // NEW
      subCategory: map['subCategory'] ?? '', // NEW
      expiryDate: map['expiryDate'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      isHalal: map['isHalal'] ?? false,
      isVegan: map['isVegan'] ?? false,
      isNoPork: map['isNoPork'] ?? false,
    );
  }

  Product copyWith({
    String? id,
    String? title,
    String? description,
    String? productType,
    String? category,    // NEW
    String? subCategory, // NEW
    String? expiryDate,
    double? originalPrice,
    double? discountedPrice,
    String? imageUrl,
    int? quantity,
    bool? isHalal,
    bool? isVegan,
    bool? isNoPork,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      productType: productType ?? this.productType,
      category: category ?? this.category,       // NEW
      subCategory: subCategory ?? this.subCategory, // NEW
      expiryDate: expiryDate ?? this.expiryDate,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      isHalal: isHalal ?? this.isHalal,
      isVegan: isVegan ?? this.isVegan,
      isNoPork: isNoPork ?? this.isNoPork,
    );
  }
}