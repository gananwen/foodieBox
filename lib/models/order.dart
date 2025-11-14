import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart'; // 导入子模型

class OrderModel {
  final String id; // 文档 ID
  final String address;
  final double deliveryFee;
  final String deliveryOption;
  final List<OrderItemModel> items;
  final String status;
  final Timestamp timestamp;
  final double total;
  final String userId; // 客户的 ID

  // --- (我们假设存在的字段) ---
  final String vendorId; // 你的（供应商的）ID
  final String orderType; // "Pickup" 或 "Delivery"

  // --- ( ✨ 修复 ✨ ) ---
  final double subtotal; // <-- 1. 添加 subtotal
  final String? driverId; // <-- 2. 添加 driverId (可为空)

  OrderModel({
    required this.id,
    required this.address,
    required this.deliveryFee,
    required this.deliveryOption,
    required this.items,
    required this.status,
    required this.timestamp,
    required this.total,
    required this.userId,
    required this.vendorId,
    required this.orderType,
    required this.subtotal, // <-- 3. 在构造函数中添加
    this.driverId, // <-- 4. 在构造函数中添加
  });

  // 从 Firestore (Map) 转换
  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      address: map['address'] ?? '',
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      deliveryOption: map['deliveryOption'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((itemMap) =>
              OrderItemModel.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      status: map['status'] ?? 'received',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      total: (map['total'] ?? 0.0).toDouble(),
      userId: map['userId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      orderType: map['orderType'] ?? 'Delivery',
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      driverId: map['driverId'],
    );
  }
}
