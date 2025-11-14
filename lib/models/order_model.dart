// 路径: lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.model.dart'; // 确保这个 import 路径正确

class OrderModel {
  final String id;
  final String userId;
  final String address;
  final double lat;
  final double lng;
  final String paymentMethod;
  final double subtotal;
  final double total;
  final String status;
  final List<OrderItem> items;
  final Timestamp timestamp;
  final String? driverId;
  final String? contactName;
  final String? contactPhone;
  final String orderType;
  final String deliveryOption;
  final double deliveryFee;
  final List<String> vendorIds;

  // --- ( ✨ 新增字段 ✨ ) ---
  // 假定客户 App 在订单完成后会更新这些字段
  final double? rating; // e.g., 4.5
  final String? reviewText; // e.g., "Great food!"
  final Timestamp? reviewTimestamp; // 评价的时间

  OrderModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.lat,
    required this.lng,
    required this.paymentMethod,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.items,
    required this.timestamp,
    this.driverId,
    this.contactName,
    this.contactPhone,
    required this.orderType,
    this.deliveryOption = 'Standard',
    this.deliveryFee = 0.0,
    required this.vendorIds,

    // --- ( ✨ 新增字段 ✨ ) ---
    this.rating,
    this.reviewText,
    this.reviewTimestamp,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    var itemsList = (map['items'] as List<dynamic>?) ?? [];
    List<OrderItem> parsedItems =
        itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'received',
      items: parsedItems,
      timestamp: map['timestamp'] ?? Timestamp.now(),
      driverId: map['driverId'],
      contactName: map['contactName'],
      contactPhone: map['contactPhone'],
      orderType: map['orderType'] ?? 'Delivery',
      deliveryOption: map['deliveryOption'] ?? 'Standard',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      vendorIds: List<String>.from(map['vendorIds'] ?? []),

      // --- ( ✨ 新增字段 ✨ ) ---
      // (使用 'as num?' 来安全地处理 double 和 int)
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['reviewText'],
      reviewTimestamp: map['reviewTimestamp'],
    );
  }
}
