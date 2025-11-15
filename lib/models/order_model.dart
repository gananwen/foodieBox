// 路径: lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// ( ✨ 关键 ✨ ) 确保你导入了下面这个 order_item.model.dart 文件
import 'order_item.model.dart';

class OrderModel {
  final String id;
  final String userId;
  final String paymentMethod;
  final double subtotal;
  final double total;
  final String status;
  final List<OrderItem> items;
  final Timestamp timestamp;
  final String? driverId;
  final String? contactName;
  final String? contactPhone;

  // --- ( ✨ 关键修复 ✨ ) ---
  // 1. 地址/经纬度 必须是可为空的 (nullable)，因为 "Pickup" 订单没有这些
  final String? address;
  final double? lat;
  final double? lng;

  // 2. 添加了 orderType, vendorIds
  final String orderType;
  final List<String> vendorIds;

  // 3. ( ✨ 关键修复 ✨ )
  // 添加了你队友模型中缺失的字段 (你的 order_page.dart 需要用到!)
  final String vendorName;
  final String vendorType;
  // --- ( ✨ 结束修复 ✨ ) ---

  // (评价字段)
  final double? rating;
  final String? reviewText;
  final Timestamp? reviewTimestamp;

  // (取货字段)
  final String? pickupId;
  final String? pickupDay; // "Today" or "Tomorrow"
  final String? pickupTime; // "12:00 PM – 1:00 PM"

  // (配送字段)
  final String deliveryOption;
  final double deliveryFee;

  OrderModel({
    required this.id,
    required this.userId,
    required this.paymentMethod,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.items,
    required this.timestamp,
    this.driverId,
    this.contactName,
    this.contactPhone,

    // --- ( ✨ 关键修复 ✨ ) ---
    this.address, // <-- 变为 nullable
    this.lat, // <-- 变为 nullable
    this.lng, // <-- 变为 nullable
    required this.orderType,
    required this.vendorIds,
    required this.vendorName, // <-- 已添加
    required this.vendorType, // <-- 已添加
    // --- ( ✨ 结束修复 ✨ ) ---

    this.deliveryOption = 'Standard', // (变为可选)
    this.deliveryFee = 0.0, // (变为可选)
    this.rating,
    this.reviewText,
    this.reviewTimestamp,
    this.pickupId,
    this.pickupDay,
    this.pickupTime,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    var itemsList = (map['items'] as List<dynamic>?) ?? [];
    List<OrderItem> parsedItems =
        itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'received',
      items: parsedItems,
      timestamp: map['timestamp'] ?? Timestamp.now(),
      driverId: map['driverId'],
      contactName: map['contactName'],
      contactPhone: map['contactPhone'],

      // --- ( ✨ 关键修复 ✨ ) ---
      // 1. 地址/经纬度 现在是 nullable
      address: map['address'], // (如果不存在，则为 null)
      lat: (map['lat'] as num?)?.toDouble(), // (如果不存在，则为 null)
      lng: (map['lng'] as num?)?.toDouble(), // (如果不存在，则为 null)

      // 2. 添加了 orderType, vendorIds
      orderType: map['orderType'] ?? 'Delivery',
      vendorIds: List<String>.from(map['vendorIds'] ?? []),

      // 3. 添加了 vendorName, vendorType
      vendorName: map['vendorName'] ?? '', // <-- 已添加
      vendorType: map['vendorType'] ?? '', // <-- 已添加
      // --- ( ✨ 结束修复 ✨ ) ---

      deliveryOption: map['deliveryOption'] ?? 'Standard',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['reviewText'],
      reviewTimestamp: map['reviewTimestamp'],
      pickupId: map['pickupId'],
      pickupDay: map['pickupDay'],
      pickupTime: map['pickupTime'],
    );
  }
}
