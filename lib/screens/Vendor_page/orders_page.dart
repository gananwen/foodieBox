import 'package:flutter/material.dart';
import '../../util/styles.dart'; // 导入你团队的样式
import 'order_details_page.dart'; // 我们下一步要创建的页面

// --- 订单列表页面 (Figure 30) ---
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _allOrders = []; // 用来存放所有订单

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 加载虚拟数据
    _loadDummyOrders();
  }

  // 模拟从 Firebase 加载数据
  void _loadDummyOrders() {
    setState(() {
      _allOrders = [
        Order(
          id: '#1111',
          type: 'Pickup',
          timestamp: '12:00 PM - 12:30 PM',
          status: 'Preparing', // 状态: 准备中
          customerName: 'Afsar Hossen',
          deliveryAddress: 'Park Way 145',
          eta: '25-30 minutes',
          subtotal: 16.97,
          discount: -7.00,
          deliveryFee: 5.00,
          // --- 新增: 备注和商品 ---
          customerNote: 'Please no peanuts, my son is allergic!',
          items: [
            OrderItem(id: 'p1', name: 'Mystery Box', quantity: 1),
            OrderItem(id: 'p2', name: 'Fresh Apples', quantity: 2),
          ],
        ),
        Order(
          id: '#1112',
          type: 'Delivery',
          timestamp: '01:00 PM - 01:30 PM',
          status: 'Ready for Pickup', // 状态: 准备好了 (用于Lalamove)
          customerName: 'Sophie Hart',
          deliveryAddress: 'Green Valley 12',
          eta: '15-20 minutes',
          subtotal: 25.50,
          discount: -5.00,
          deliveryFee: 5.00,
          // --- 新增: 备注和商品 ---
          customerNote: 'Extra chili flakes please, thank you!',
          items: [
            OrderItem(id: 'p3', name: 'Fresh Orange', quantity: 5),
            OrderItem(id: 'p5', name: 'Fresh Corn', quantity: 4),
          ],
        ),
        Order(
          id: '#1113',
          type: 'Pickup',
          timestamp: '02:00 PM - 02:30 PM',
          status: 'Completed', // 状态: 已完成
          customerName: 'Dave David',
          deliveryAddress: 'N/A',
          eta: 'N/A',
          subtotal: 12.00,
          discount: 0,
          deliveryFee: 0,
          // --- 新增: 备注和商品 ---
          customerNote: '', // 没有备注
          items: [
            OrderItem(id: 'p4', name: 'Fresh Mango', quantity: 3),
          ],
        ),
        Order(
          id: '#1114',
          type: 'Delivery',
          timestamp: '03:00 PM - 03:30 PM',
          status: 'Delivering', // 状态: 派送中
          customerName: 'Elysha Sophia',
          deliveryAddress: 'Cyberjaya 77',
          eta: '5-10 minutes',
          subtotal: 30.00,
          discount: -10.00,
          deliveryFee: 5.00,
          // --- 新增: 备注和商品 ---
          customerNote: 'Please leave at guard house.',
          items: [
            OrderItem(id: 'p1', name: 'Mystery Box', quantity: 2),
          ],
        ),
      ];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- 这是你要求的自定义状态徽章 (Status Badge) ---
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    switch (status) {
      case 'Preparing':
        // 准备中 (使用浅黄色)
        badgeColor = Colors.amber[100] ?? Colors.amber;
        statusText = 'Preparing';
        break;
      case 'Ready for Pickup':
        // 准备好了/待取货 (使用你的浅绿色)
        badgeColor = kSecondaryAccentColor;
        statusText = 'Ready for Pickup';
        break;
      case 'Delivering':
        // 派送中 (也使用浅绿色，表示已发出)
        badgeColor = kSecondaryAccentColor;
        statusText = 'Delivering';
        break;
      case 'Completed':
        // 已完成 (使用灰色)
        badgeColor = Colors.grey[300] ?? Colors.grey;
        statusText = 'Completed';
        break;
      default:
        badgeColor = Colors.grey[300] ?? Colors.grey;
        statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20), // 圆角
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

  // --- 构建订单卡片 (没有照片) ---
  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kCardColor, // 白色
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          'Order ${order.id}',
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
              order.timestamp,
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            // 在这里使用你自定义的状态徽章
            _buildStatusBadge(order.status),
          ],
        ),
        // 右侧的箭头
        trailing: const Icon(Icons.chevron_right, color: kTextColor),
        onTap: () {
          // 跳转到订单详情页 (Figure 31)
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

  // --- 构建订单列表 (根据 'Pickup' 或 'Delivery' 过滤) ---
  Widget _buildOrderList(String type) {
    // 过滤出 "Completed" 之外的订单
    final activeOrders = _allOrders
        .where((o) => o.type == type && o.status != 'Completed')
        .toList();

    if (activeOrders.isEmpty) {
      return Center(
        child: Text(
          'No active $type orders.',
          style: TextStyle(color: kTextColor.withOpacity(0.6)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(activeOrders[index]);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        // TabBar: "Pickup" 和 "Delivery"
        bottom: TabBar(
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
        controller: _tabController,
        children: [
          // Pickup 列表
          _buildOrderList('Pickup'),
          // Delivery 列表
          _buildOrderList('Delivery'),
        ],
      ),
    );
  }
}

// --- 商品数据模型 (Item Data Model) ---
class OrderItem {
  final String id;
  final String name;
  final int quantity;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
  });
}

// --- 订单数据模型 (Order Data Model) ---
// 这个类用来存放订单信息，方便传递
class Order {
  final String id;
  final String type; // 'Pickup' or 'Delivery'
  final String timestamp;
  final String status; // 'Preparing', 'Ready for Pickup', etc.
  final String customerName;
  final String deliveryAddress;
  final String eta;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  // --- 新增字段 ---
  final String customerNote;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.customerName,
    required this.deliveryAddress,
    required this.eta,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.customerNote,
    required this.items,
  });
}
