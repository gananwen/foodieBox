// 路径: lib/repositories/order_repository.dart
import 'dart:math'; // 用于随机司机
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart'; // 确保 import 路径正确

class OrderRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 获取当前供应商的 UID
  String? get _vendorId => _auth.currentUser?.uid;

  // --- 1. 获取订单列表 (用于 Orders Page) ---
  // ( ✨ 已包含你对 "paid pending pickup" 状态的修复 ✨ )
  Stream<List<OrderModel>> getOrdersStream(String orderType) {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId) // ( ❗ 依赖客户 App 修复 ❗ )
        .where('orderType', isEqualTo: orderType)
        .where('status', whereIn: [
          'received',
          'Preparing',
          'Ready for Pickup',
          'Delivering',
          'paid pending pickup' // ( ✨ 已添加 ✨ )
        ])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic>? data = doc.data();
            if (data == null) {
              throw Exception('Found order with empty data: ${doc.id}');
            }
            return OrderModel.fromMap(data, doc.id);
          }).toList();
        });
  }

  // --- 2. 更新订单状态 (用于 Details Page) ---
  // ( ✨ 这是你缺失的函数之一 ✨ )
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // --- 3. 分配司机 (用于 Details Page) ---
  // ( ✨ 这是你缺失的函数之二 ✨ )
  Future<void> assignDriverToOrder(String orderId) async {
    try {
      final driversSnapshot = await _db.collection('drivers').get();

      if (driversSnapshot.docs.isEmpty) {
        throw Exception('No drivers found to assign.');
      }

      final drivers = driversSnapshot.docs;
      final randomDriver = drivers[Random().nextInt(drivers.length)];
      final driverId = randomDriver.id;

      await _db
          .collection('orders')
          .doc(orderId)
          .update({'driverId': driverId});

      print('Assigned driver $driverId to order $orderId');
    } catch (e) {
      print('Error assigning driver: $e');
      rethrow;
    }
  }

  // --- 4. 获取今日统计 (用于 Home Page Dashboard) ---
  // ( ✨ 这是你缺失的函数之三 ✨ )
  Stream<Map<String, dynamic>> getTodaysStatsStream() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

    final query = _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId) // ( ❗ 依赖客户 App 修复 ❗ )
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp);

    return query.snapshots().map((snapshot) {
      int orderCount = snapshot.docs.length;
      double totalSales = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('total')) {
          totalSales += (data['total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'orderCount': orderCount,
        'totalSales': totalSales,
      };
    });
  }
}
