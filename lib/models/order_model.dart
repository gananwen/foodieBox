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
  final double? rating;
  final String? reviewText;
  final Timestamp? reviewTimestamp;

  // --- ( ✨ 关键修复 ✨ ) ---
  // (这些字段现在被添加到了模型中)
  final String? pickupId;
  final String? pickupDay; // "Today" or "Tomorrow"
  final String? pickupTime; // "12:00 PM – 1:00 PM"
  // --- ( ✨ 结束修复 ✨ ) ---

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
    this.rating,
    this.reviewText,
    this.reviewTimestamp,

    // --- ( ✨ 关键修复 ✨ ) ---
    this.pickupId,
    this.pickupDay,
    this.pickupTime,
    // --- ( ✨ 结束修复 ✨ ) ---
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
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['reviewText'],
      reviewTimestamp: map['reviewTimestamp'],

      // --- ( ✨ 关键修复 ✨ ) ---
      // (现在 App 会从 Firebase 正确读取这些字段)
      pickupId: map['pickupId'],
      pickupDay: map['pickupDay'],
      pickupTime: map['pickupTime'],
      // --- ( ✨ 结束修复 ✨ ) ---
    );
  }
}
