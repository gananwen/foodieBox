// 路径: lib/repositories/order_repository.dart
import 'dart:math'; // 用于随机司机
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart'; // 确保 import 路径正确

class OrderRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _vendorId => _auth.currentUser?.uid;

  Stream<List<OrderModel>> getOrdersStream(String orderType) {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId) // <-- ( ✨ 已修复! ✨ )
        .where('orderType', isEqualTo: orderType) // <-- ( ✨ 正确! ✨ )

        // --- ( ✨ 关键修复 ✨ ) ---
        // 我们把带空格的 'paid pending pickup'
        // 改成你新数据里带下划线的 'paid_pending_pickup'
        .where('status', whereIn: [
          'received',
          'Preparing',
          'Ready for Pickup',
          'Delivering',
          'paid_pending_pickup' // <-- ( ✨ 修复为下划线版本 ✨ )
        ])
        // --- ( ✨ 结束修复 ✨ ) ---

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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

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
        .where('vendorIds', arrayContains: vendorId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp);

    // 监听快照
    return query.snapshots().map((snapshot) {
      int orderCount = snapshot.docs.length;
      double totalSales = 0.0;

      // 遍历所有文档
      for (var doc in snapshot.docs) {
        // --- ( ✨ 关键修复 ✨ ) ---
        // 1. 安全地获取数据
        final data = doc.data() as Map<String, dynamic>?;

        // 2. 检查 'total' 字段是否存在
        if (data != null && data.containsKey('total')) {
          // 3. 安全地检查 'total' 是不是一个 *数字* (Number)
          final totalValue = data['total'];
          if (totalValue is num) {
            // 4. 只有当它 *是* 数字时，才进行加法
            totalSales += totalValue.toDouble();
          }
          // (如果 totalValue 是 "32" (String) 或 null, 它会被安全地忽略)
        }
        // --- ( ✨ 结束修复 ✨ ) ---
      }

      return {
        'orderCount': orderCount,
        'totalSales': totalSales,
      };
    });
  }
}
