// 路径: lib/pages/vendor_home/orders_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 导入 intl
import '../../util/styles.dart';
import 'order_details_page.dart';
import '../../models/order_model.dart';
import '../../repositories/order_repository.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const OrdersPage({super.key, required this.onBackToDashboard});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // --- 2. 实例化仓库 ---
  final OrderRepository _repo = OrderRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- (不变) 状态徽章 ---
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    switch (status) {
      // ( ✨ 新增 Case ✨ )
      case 'paid_pending_pickup':
        badgeColor = Colors.blue[100] ?? Colors.blue;
        statusText = 'Pending Pickup';
        break;

      case 'received':
        badgeColor = Colors.blue[100] ?? Colors.blue;
        statusText = 'New Order';
        break;
      case 'Preparing':
        badgeColor = Colors.amber[100] ?? Colors.amber;
        statusText = 'Preparing';
        break;
      case 'Ready for Pickup':
        badgeColor = kSecondaryAccentColor;
        statusText = 'Ready for Pickup';
        break;
      case 'Delivering':
        badgeColor = kSecondaryAccentColor;
        statusText = 'Delivering';
        break;
      case 'Completed':
        badgeColor = Colors.grey[300] ?? Colors.grey;
        statusText = 'Completed';
        break;
      default:
        badgeColor = Colors.grey[300] ?? Colors.grey;
        // ( ✨ 修复：替换掉下划线 ✨ )
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

  // --- 4. (已修改) 构建订单卡片 ---
  Widget _buildOrderCard(OrderModel order) {
    // 格式化时间戳
    final String timeAgo =
        DateFormat('dd MMM, hh:mm a').format(order.timestamp.toDate());

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
          'Order #${order.id.substring(0, 6)}...', // 缩短 ID
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
              timeAgo, // (已修改) 使用真实时间
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusBadge(order.status), // (已修改) 使用真实状态
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailsPage(order: order), // 5. (已修改) 传递 OrderModel
            ),
          );
        },
      ),
    );
  }

  // --- 6. (已修改) 构建订单列表 ---
  Widget _buildOrderList(String type) {
    return StreamBuilder<List<OrderModel>>(
      // 7. (已修改) 使用仓库的 Stream
      stream: _repo.getOrdersStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor));
        }
        if (snapshot.hasError) {
          // ( ✨ 提示 ✨ ) 这里是你的 Firebase 权限错误最先出现的地方
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
              'No active $type orders.',
              style: TextStyle(color: kTextColor.withOpacity(0.6)),
            ),
          );
        }

        // 我们有数据了
        final activeOrders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(activeOrders[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Active Orders'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: widget.onBackToDashboard,
        ),
        bottom: TabBar(
          // ... (不变)
          controller: _tabController,
          indicatorColor: kTextColor,
          labelColor: kTextColor,
          unselectedLabelColor: kTextColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Pickup'),
            Tab(text: 'Delivery'),
          ],
        ),
      ),
      body: TabBarView(
        // ... (不变)
        controller: _tabController,
        children: [
          _buildOrderList('Pickup'),
          _buildOrderList('Delivery'),
        ],
      ),
    );
  }
}
