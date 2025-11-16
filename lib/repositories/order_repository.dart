// 路径: lib/repositories/order_repository.dart
import 'dart:math'; // 用于随机司机
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart'; // 确保 import 路径正确

class OrderRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _vendorId => _auth.currentUser?.uid;

  // --- ( 这是你现有的函数 - 保持不变 ) ---
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
          'Pending Payment', // <-- NEW STATUS
          'Payment Rejected', // <-- NEW STATUS
          'Delivered',
          'Picked Up'
          'Cancelled' // <-- ( ✨ NEWLY ADDED ✨ )
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

  // --- ( 这是你现有的函数 - 保持不变 ) ---
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // --- ( 这是你现有的函数 - 保持不变 ) ---
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

  // --- ( 这是你现有的函数 - 保持不变 ) ---
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
        nowInMalaysia.year, nowInMalaysia.month, nowInMalaysia.day, 0, 0, 0);
    // 4. 将 UTC+8 的凌晨时间转换回 UTC 时间戳进行查询
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
  Stream<List<OrderModel>> getHistoryOrdersStream() {
    final vendorId = _vendorId;
    if (vendorId == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('orders')
        .where('vendorIds', arrayContains: vendorId)
        // ( 关键 ) 查询 "Completed" 和 "Cancelled" 状态
        .where('status', whereIn: ['Completed', 'Cancelled'])
        // ( 索引 ) 这个查询需要一个新的索引
        .orderBy('timestamp', descending: true)
        .limit(50) // (可选：对历史记录进行分页或限制)
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

  // --- ( ✨✨✨ IMPORTANT ✨✨✨ ) ---
  //
  // This function should ONLY be called by your Admin Panel or
  // a Firebase Cloud Function *after* an Admin approves the payment.
  //
  // DO NOT call this from the customer app.
  //
  Future<void> deductStockForOrder(OrderModel order) async {
    // Use a transaction to ensure this is atomic (all or nothing)
    await _db.runTransaction((transaction) async {
      for (final item in order.items) {
        // 1. Get the reference to the product document
        final productRef = _db
            .collection('vendors')
            .doc(item.vendorId)
            .collection('products')
            .doc(item.productId);

        // 2. Get the product document *within the transaction*
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception(
              'Product with ID ${item.productId} not found for vendor ${item.vendorId}.');
        }

        // 3. Get the current stock ('quantity' field in product.dart)
        final currentStock = (productSnapshot.data()?['quantity'] as num?) ?? 0;

        // 4. Calculate the new stock
        final newStock = currentStock - item.quantity;

        // 5. Update the product document *within the transaction*
        // Set new stock, ensuring it doesn't go below 0.
        transaction.update(productRef, {
          'quantity': newStock < 0 ? 0 : newStock,
        });
      }
    });
    print('Stock successfully deducted for order ${order.id}');
  }
  // --- ( ✨✨✨ END OF CHANGE ✨✨✨ ) ---
}