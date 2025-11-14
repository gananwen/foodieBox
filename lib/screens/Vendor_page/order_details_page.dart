// 路径: lib/pages/vendor_home/order_details_page.dart
import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../models/order_model.dart';
import '../../models/order_item.model.dart'; // ( ✨ 确保 import 路径正确 ✨ )
import '../../repositories/order_repository.dart'; // ( ✨ 确保 import 路径正确 ✨ )

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String _currentStatus;
  final OrderRepository _repo = OrderRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  // --- ( ✨ 这是你的核心逻辑 ✨ ) ---
  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      // 1. 始终更新状态
      await _repo.updateOrderStatus(widget.order.id, newStatus);

      // --- 2. ( ✨ 新增 ✨ ) 检查触发条件 ---
      // 如果你点击了 "Ready for Pickup"，则分配一个司机
      if (newStatus == 'Ready for Pickup') {
        // 这是 "auto random come out" 的触发器
        await _repo.assignDriverToOrder(widget.order.id);
      }

      // 3. 更新 UI
      setState(() {
        _currentStatus = newStatus;
      });

      if (mounted) {
        String message = 'Order status updated to $newStatus';
        if (newStatus == 'Ready for Pickup') {
          message += ' & Driver assigned!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: kSecondaryAccentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: kPrimaryActionColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- (不变) _buildSectionHeader ---
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

  // --- (不变) _buildPriceRow ---
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

  // --- (不变) _buildStatusButton ---
  Widget _buildStatusButton(String title, String statusKey) {
    final bool isSelected = (_currentStatus == statusKey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: isSelected
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryAccentColor,
                foregroundColor: kTextColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: null,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )
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
              onPressed: _isLoading
                  ? null
                  : () {
                      _updateOrderStatus(statusKey);
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kTextColor,
                      ),
                    )
                  : Text(title),
            ),
    );
  }

  // --- ( ✨ 已修改 ✨ ) _buildOrderItemList ---
  Widget _buildOrderItemList(List<OrderItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
      ),
      child: ListView.separated(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: Text(
              'RM${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: kTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(color: kTextColor),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(
            height: 1,
            color: kAppBackgroundColor,
            indent: 16,
            endIndent: 16,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ( ✨ 已修改 ✨ )
    // 我们现在从更新后的 OrderModel 中获取这些值
    final double total = widget.order.total;
    final double subtotal = widget.order.subtotal;
    final double deliveryFee = widget.order.deliveryFee;

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
            // --- 1. Customer Details ---
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
                  'Customer ID: ...${widget.order.userId.substring(widget.order.userId.length - 6)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kTextColor),
                ),
                subtitle: Text(
                  // ( ✨ 已修改 ✨ ) 使用新的 'orderType' 字段
                  widget.order.orderType == 'Pickup'
                      ? 'Self-Pickup Order'
                      : '${widget.order.address}\nDelivery: ${widget.order.deliveryOption}',
                  style: TextStyle(color: kTextColor.withOpacity(0.7)),
                ),
              ),
            ),

            // --- 2. Items Ordered ---
            _buildSectionHeader('Items Ordered'),
            _buildOrderItemList(widget.order.items),

            // --- 3. Order Summary ---
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
                  const SizedBox(height: 10),
                  _buildPriceRow(
                      'Subtotal', 'RM${subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Standard delivery',
                      'RM${deliveryFee.toStringAsFixed(2)}'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildPriceRow('Total', 'RM${total.toStringAsFixed(2)}',
                      isTotal: true),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // --- 4. Status Update ---
            _buildSectionHeader('Status'),
            // (我们假设 'received' 是初始状态)
            _buildStatusButton('Preparing', 'Preparing'),

            // ( ✨ 已修改 ✨ ) 使用新的 'orderType' 字段来决定显示哪个按钮
            if (widget.order.orderType == 'Pickup') ...[
              _buildStatusButton('Ready for Pickup', 'Ready for Pickup'),
            ] else ...[
              // 这是你的触发器按钮
              _buildStatusButton(
                  'Ready for Pickup (Request Lalamove)', 'Ready for Pickup'),
              _buildStatusButton(
                  'Delivering',
                  // ( ✨ 已修改 ✨ ) 检查 driverId 是否存在
                  (widget.order.driverId != null &&
                          widget.order.driverId!.isNotEmpty)
                      ? 'Delivering'
                      : _currentStatus), // 只有在分配了司机后才能点击 "Delivering"
            ],

            _buildStatusButton('Completed', 'Completed'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
