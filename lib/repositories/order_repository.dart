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
        // 添加了 'Prepared' 状态
        .where('status', whereIn: [
          'Received',
          'Preparing',
          'Prepared', // <-- ( ✨ 新增状态 ✨ )
          'Ready for Pickup',
          'Delivering',
          'paid_pending_pickup',
          'Delivered',
          'Picked Up'
          'Cancelled' // <-- ( ✨ NEWLY ADDED ✨ )
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

    // --- ( ✨ 关键修复：时区 ✨ ) ---
    // 1. 获取当前的 UTC 时间
    final nowUtc = DateTime.now().toUtc();

    // 2. 手动将当前 UTC 时间调整为 UTC+8
    final nowInMalaysia = nowUtc.add(const Duration(hours: 8));

    // 3. 计算 UTC+8 时区的 "今天凌晨"
    final startOfTodayInMalaysia = DateTime.utc(
        nowInMalaysia.year,
        nowInMalaysia.month,
        nowInMalaysia.day,
        0,
        0,
        0); // 这创建了 '2025-11-15 00:00:00' (UTC)

    // 4. 将这个 UTC 时间转换回 UTC+8 的 "凌晨"，即减去8小时
    //    这给了我们 '2025-11-14 16:00:00' (UTC)，这才是 UTC+8 的午夜
    final startOfTodayTimestamp = Timestamp.fromDate(
        startOfTodayInMalaysia.subtract(const Duration(hours: 8)));
    // --- ( ✨ 结束修复 ✨ ) ---

    // 5. 查询 (这个查询现在是正确的)
    // (它在查询: ...where('timestamp', >= '2025-11-14 16:00:00 UTC') )
    final query = _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp);

    // 6. 监听快照 (这个逻辑是我们之前修复过的，是安全的)
    return query.snapshots().map((snapshot) {
      int orderCount = snapshot.docs.length;
      double totalSales = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('total')) {
          final totalValue = data['total'];
          if (totalValue is num) {
            totalSales += totalValue.toDouble();
          }
        }
      }

      return {
        'orderCount': orderCount,
        'totalSales': totalSales,
      };
    });
  }
}