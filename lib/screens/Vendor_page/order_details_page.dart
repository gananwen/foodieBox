import 'package:flutter/material.dart';
import '../../util/styles.dart'; // 导入你的样式
import 'orders_page.dart'; // 导入 Order 和 OrderItem 数据模型

// --- 订单详情页 (Figure 31) ---
class OrderDetailsPage extends StatefulWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  void _updateOrderStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });

    // TODO: 在这里将 newStatus 更新到 Firebase

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated to $newStatus'),
        backgroundColor: kPrimaryActionColor, // 绿色
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- 辅助 Widget：用于构建分区标题 ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- 辅助 Widget：用于构建价格明细行 ---
  Widget _buildPriceRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: kTextColor.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: kTextColor,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- 辅助 Widget：用于构建状态按钮 ---
  Widget _buildStatusButton(String title, String statusKey) {
    final bool isSelected = (_currentStatus == statusKey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: isSelected
          // 1. 选中的按钮 (绿色背景)
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryAccentColor, // 你的浅绿色
                foregroundColor: kTextColor,
                minimumSize: const Size(double.infinity, 50), // 撑满宽度
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: null, // 已经是这个状态了，禁止点击
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          // 2. 未选中的按钮 (白色描边)
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side:
                    BorderSide(color: kTextColor.withOpacity(0.3), width: 1.5),
              ),
              onPressed: () {
                _updateOrderStatus(statusKey);
              },
              child: Text(title),
            ),
    );
  }

  // --- (新增) 辅助 Widget：用于显示客户备注 ---
  Widget _buildCustomerNote(String note) {
    // 如果备注为空，则不显示
    if (note.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
        ),
        child: Text(
          'No special requests from customer.',
          style: TextStyle(
              color: kTextColor.withOpacity(0.5), fontStyle: FontStyle.italic),
        ),
      );
    }

    // 如果有备注，用显眼的样式显示
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kAppBackgroundColor, // 你的浅黄色背景
        borderRadius: BorderRadius.circular(12),
        // 使用高亮色 (Pink) 边框来吸引注意
        border: Border.all(color: kPrimaryActionColor, width: 2.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, color: kTextColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                  color: kTextColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- (新增) 辅助 Widget：用于显示商品列表 ---
  Widget _buildOrderItemList(List<OrderItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
      ),
      // --- 修复开始: 使用 ListView.separated ---
      child: ListView.separated(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),

        // 1. itemBuilder 仍然构建 ListTile
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            // 商品数量 (e.g., "2x")
            leading: Text(
              '${item.quantity}x',
              style: const TextStyle(
                color: kTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 商品名称
            title: Text(
              item.name,
              style: const TextStyle(color: kTextColor),
            ),
            // --- 修复: 移除了错误的 trailing 属性 ---
          );
        },

        // 2. separatorBuilder 专门用来构建分隔线
        separatorBuilder: (context, index) {
          return const Divider(
            height: 1,
            color: kAppBackgroundColor, // 用背景色做分隔线更美观
            indent: 16,
            endIndent: 16,
          );
        },
      ),
      // --- 修复结束 ---
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算总价
    final double total = widget.order.subtotal +
        widget.order.discount +
        widget.order.deliveryFee;

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Orders Details'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 客户详情 (Customer Details) ---
            _buildSectionHeader('Customer'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: kSecondaryAccentColor,
                  child: const Icon(Icons.person, color: kTextColor),
                ),
                title: Text(
                  widget.order.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kTextColor),
                ),
                subtitle: Text(
                  widget.order.type == 'Pickup'
                      ? 'Self-Pickup Order'
                      : '${widget.order.deliveryAddress}\nEstimate time: ${widget.order.eta}',
                  style: TextStyle(color: kTextColor.withOpacity(0.7)),
                ),
              ),
            ),

            // --- 2. (新增) 客户备注 ---
            _buildSectionHeader('Customer Note (备注)'),
            _buildCustomerNote(widget.order.customerNote),

            // --- 3. (更新) 商品列表 ---
            _buildSectionHeader('Items Ordered'),
            _buildOrderItemList(widget.order.items),

            // --- 4. 价格小结 ---
            _buildSectionHeader('Order Summary'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10), // 顶部间距
                  _buildPriceRow('Subtotal',
                      'RM${widget.order.subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Total discount',
                      'RM${widget.order.discount.toStringAsFixed(2)}'),
                  _buildPriceRow('Standard delivery',
                      'RM${widget.order.deliveryFee.toStringAsFixed(2)}'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildPriceRow('Total', 'RM${total.toStringAsFixed(2)}',
                      isTotal: true),
                  const SizedBox(height: 10), // 底部间距
                ],
              ),
            ),

            // --- 5. 状态更新 (Status Update) ---
            _buildSectionHeader('Status'),
            _buildStatusButton('Preparing', 'Preparing'),

            if (widget.order.type == 'Pickup') ...[
              // 1. 如果是 "Pickup" 订单
              _buildStatusButton('Ready for Pickup', 'Ready for Pickup'),
            ] else ...[
              // 2. 如果是 "Delivery" 订单
              _buildStatusButton(
                  'Ready for Pickup (Request Lalamove)', 'Ready for Pickup'),
              _buildStatusButton('Delivering', 'Delivering'),
            ],

            _buildStatusButton('Completed', 'Completed'),

            const SizedBox(height: 40), // 底部留白
          ],
        ),
      ),
    );
  }
}
