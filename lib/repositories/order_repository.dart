import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
// --- 1. 导入 Driver 模型 ---
import '../models/driver_model.dart';
import 'driver_repository.dart'; // 导入 Driver 仓库

class OrderRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 2. (新增) 实例化 Driver 仓库 ---
  final DriverRepository _driverRepo = DriverRepository();

  String? get _vendorId => _auth.currentUser?.uid;

  // --- (不变) 读取订单流 ---
  Stream<List<OrderModel>> getOrdersStream(String orderType) {
    final vendorId = _vendorId;
    if (vendorId == null) throw Exception('User not logged in');

    return _db
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .where('orderType', isEqualTo: orderType)
        .where('status', isNotEqualTo: 'Completed')
        .orderBy('status')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()!, doc.id))
          .toList();
    });
  }

  // --- (不变) 更新订单状态 ---
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // --- 3. (新增) 分配司机给订单的函数 ---
  Future<void> assignDriverToOrder(String orderId) async {
    try {
      // 1. 获取一个随机司机
      final DriverModel? randomDriver = await _driverRepo.getRandomDriver();
      if (randomDriver == null) {
        throw Exception("No drivers available to assign.");
      }

      // 2. 将该司机的 ID 更新到 'orders' 文档中
      await _db.collection('orders').doc(orderId).update({
        'driverId': randomDriver.id, // <-- 关键步骤！
      });
    } catch (e) {
      print('Error assigning driver: $e');
      rethrow;
    }
  }
}
