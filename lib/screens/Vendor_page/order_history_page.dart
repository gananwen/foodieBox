// 路径: lib/pages/vendor_home/order_history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import 'order_details_page.dart';
import '../../models/order_model.dart';
import '../../repositories/order_repository.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderRepository _repo = OrderRepository();

  // ( ✨ 关键 ✨ )
  // 这个 Stream 从你的仓库中获取 "Completed" 和 "Cancelled" 的订单
  late Stream<List<OrderModel>> _historyStream;

  @override
  void initState() {
    super.initState();
    // ( ✨ 关键 ✨ )
    // 这就是你刚刚在 order_repository.dart 中添加的新函数
    _historyStream = _repo.getHistoryOrdersStream();
  }

  // --- ( 1. 从 orders_page.dart 复制粘贴 ) ---
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    switch (status) {
      // (你可以在这里移除 active 状态，只保留历史状态)
      case 'Completed':
        badgeColor = Colors.grey[300] ?? Colors.grey;
        statusText = 'Completed';
        break;
      case 'Cancelled':
        badgeColor = Colors.red[100] ?? Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        // (作为备用)
        badgeColor = Colors.grey[300] ?? Colors.grey;
        statusText = status.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- ( 2. 从 orders_page.dart 复制粘贴 ) ---
  Widget _buildOrderCard(OrderModel order) {
    // ( ✨ 建议：对历史记录使用更完整的日期格式 )
    final String timeAgo =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.timestamp.toDate());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          'Order #${order.id.substring(0, 6)}...',
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeAgo,
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusBadge(order.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextColor),
        onTap: () {
          // ( 同样导航到详情页 )
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(order: order),
            ),
          );
        },
      ),
    );
  }

  // --- ( 3. 构建页面 ) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
            // ( ✨ 提示 ✨ )
            // 如果你在这里看到一个 "FAILED_PRECONDITION" 错误,
            // 那就是 Firebase 在要求你创建新索引
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: kPrimaryActionColor)),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No order history found.',
                style: TextStyle(color: kTextColor.withOpacity(0.6)),
              ),
            );
          }

          final historyOrders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: historyOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(historyOrders[index]);
            },
          );
        },
      ),
    );
  }
}
