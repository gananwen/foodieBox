// 路径: lib/pages/vendor_home/order_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import '../../models/order_model.dart';
import '../../models/order_item.model.dart';
import '../../repositories/order_repository.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  // ... (initState, _updateOrderStatus, _buildSectionHeader, _buildPriceRow, _buildStatusButton, _buildOrderItemList, _buildInfoRow 都保持不变) ...
  late String _currentStatus;
  final OrderRepository _repo = OrderRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _repo.updateOrderStatus(widget.order.id, newStatus);
      if (newStatus == 'Ready for Pickup' &&
          widget.order.orderType == 'Delivery') {
        await _repo.assignDriverToOrder(widget.order.id);
      }
      setState(() {
        _currentStatus = newStatus;
      });
      if (mounted) {
        String message = 'Order status updated to $newStatus';
        if (newStatus == 'Ready for Pickup' &&
            widget.order.orderType == 'Delivery') {
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kTextColor.withAlpha(150), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: kTextColor.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    // ... (Timestamp 和 OrderID 逻辑不变) ...
    final String formattedTimestamp =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.timestamp.toDate());
    final String orderId = order.id.substring(0, 6).toUpperCase();

    // ... (pickupDateString 逻辑不变) ...
    String pickupDateString = 'N/A';
    final DateTime orderDate = order.timestamp.toDate();
    if (order.pickupDay == 'Today') {
      pickupDateString = DateFormat('dd MMM yyyy (Today)').format(orderDate);
    } else if (order.pickupDay == 'Tomorrow') {
      final tomorrow = orderDate.add(const Duration(days: 1));
      pickupDateString = DateFormat('dd MMM yyyy (Tomorrow)').format(tomorrow);
    } else if (order.pickupDay != null) {
      pickupDateString = order.pickupDay!;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (ID, Timestamp, Pickup Date, Pickup Slot, Pickup Code 不变) ...
          _buildInfoRow(
            Icons.confirmation_number_outlined,
            'Order ID',
            orderId,
          ),
          const Divider(color: kAppBackgroundColor),
          _buildInfoRow(
            Icons.access_time,
            'Order Placed',
            formattedTimestamp,
          ),
          const Divider(color: kAppBackgroundColor),

          if (order.orderType == 'Pickup') ...[
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Pickup Date',
              pickupDateString,
            ),
            const Divider(color: kAppBackgroundColor),
            _buildInfoRow(
              Icons.schedule_outlined,
              'Pickup Slot',
              order.pickupTime ?? 'N/A',
            ),
            if (order.pickupId != null) ...[
              const Divider(color: kAppBackgroundColor),
              _buildInfoRow(
                Icons.vpn_key_outlined,
                'Pickup Code',
                order.pickupId!,
              ),
            ]
          ] else ...[
            // --- ( ✨ 关键修复 ✨ ) ---
            // 'order.address' 是 String? (nullable)
            // 我们必须给它一个备用值，以防它是 null
            _buildInfoRow(
              Icons.location_on_outlined,
              'Delivery Address',
              order.address ?? 'N/A', // <-- 修复了错误
            ),
            // --- ( ✨ 结束修复 ✨ ) ---
            const Divider(color: kAppBackgroundColor),
            _buildInfoRow(
              Icons.delivery_dining_outlined,
              'Delivery Option',
              order.deliveryOption, // (这个是 String, 不是 nullable, 所以没问题)
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build 方法的其余部分不变) ...
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
                  widget.order.orderType == 'Pickup'
                      ? 'Self-Pickup Order'
                      : 'Delivery Order',
                  style: TextStyle(color: kTextColor.withOpacity(0.7)),
                ),
              ),
            ),
            _buildSectionHeader('Order Details'),
            _buildOrderInfoCard(widget.order),
            _buildSectionHeader('Items Ordered'),
            _buildOrderItemList(widget.order.items),
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
            _buildSectionHeader('Status'),
            _buildStatusButton('Paid (Pending Pickup)', 'paid_pending_pickup'),
            _buildStatusButton('Preparing', 'Preparing'),
            if (widget.order.orderType == 'Pickup') ...[
              _buildStatusButton('Ready for Pickup', 'Ready for Pickup'),
            ] else ...[
              _buildStatusButton(
                  'Ready for Pickup (Request Lalamove)', 'Ready for Pickup'),
              _buildStatusButton(
                  'Delivering',
                  (widget.order.driverId != null &&
                          widget.order.driverId!.isNotEmpty)
                      ? 'Delivering'
                      : _currentStatus),
            ],
            _buildStatusButton('Completed', 'Completed'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}