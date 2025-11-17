import 'package:flutter/material.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:intl/intl.dart';
import 'package:foodiebox/models/order_item.model.dart'; // 确保导入
// --- ( ✨ NEW IMPORT - This is required for the rating page ✨ ) ---
import 'package:foodiebox/screens/users/rate_order_page.dart';
// --- ( ✨ END NEW IMPORT ✨ ) ---

class OrderHistoryDetailsPage extends StatelessWidget {
  final OrderModel order;

  const OrderHistoryDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String formattedDateTime =
        DateFormat('dd/MM/yyyy, hh:mm a').format(order.timestamp.toDate());
    
    // 从 OrderModel 获取数据，而不是从 checkout_page
    final double discount = order.subtotal - order.total + order.deliveryFee;
    final String? voucherLabel = order.voucherLabel; // 假设 OrderModel 有这个字段
    final String? promoLabel = order.promoLabel; // 假设 OrderModel 有这个字段

    String appliedDiscountLabel = 'Discount';
    if (voucherLabel != null && voucherLabel.isNotEmpty) {
      appliedDiscountLabel = voucherLabel;
    } else if (promoLabel != null && promoLabel.isNotEmpty) {
      appliedDiscountLabel = promoLabel;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info
            Text(
              order.vendorName ?? 'Store',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
            ),
            const SizedBox(height: 8),
            if (order.vendorAddress != null && order.vendorAddress!.isNotEmpty)
              Text(
                order.vendorAddress!,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            
            // Order Info
            _buildInfoCard(
              formattedDateTime,
              order.id,
              order.status[0].toUpperCase() + order.status.substring(1),
              order.orderType,
            ),
            const SizedBox(height: 20),

            // Items List
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return _buildItemTile(item);
                },
                separatorBuilder: (context, index) => const Divider(height: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', order.subtotal),
                  if (discount > 0)
                    _buildSummaryRow(
                      appliedDiscountLabel, 
                      -discount, 
                      isDiscount: true
                    ),
                  if (order.orderType == 'Delivery')
                    _buildSummaryRow('Delivery Fee', order.deliveryFee),
                  
                  const Divider(height: 20, thickness: 1),
                  
                  _buildSummaryRow('Total', order.total, isTotal: true),
                ],
              ),
            ),

            // --- ( ✨ NEWLY ADDED REVIEW SECTION ✨ ) ---
            const SizedBox(height: 20),
            _buildReviewSection(context, order),
            const SizedBox(height: 20),
            // --- ( ✨ END NEWLY ADDED ✨ ) ---
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String date, String orderId, String status, String type) {
    IconData statusIcon;
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
      case 'picked up':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.history;
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID: ${orderId.substring(0, 8)}...', style: kHintTextStyle),
              Text(date, style: kHintTextStyle),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status', style: kHintTextStyle),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: kLabelTextStyle.copyWith(color: statusColor, fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Order Type', style: kHintTextStyle),
                  Text(
                    type,
                    style: kLabelTextStyle.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderItem item) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(item.imageUrl.isNotEmpty
                  ? item.imageUrl
                  : 'https://placehold.co/600x400/FFF8E1/E6A000?text=Item'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: kLabelTextStyle.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.quantity}x',
                style: kHintTextStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'RM${(item.price * item.quantity).toStringAsFixed(2)}',
          style: kLabelTextStyle.copyWith(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    final style = isTotal
        ? kLabelTextStyle.copyWith(fontSize: 18, color: kPrimaryActionColor)
        : kLabelTextStyle.copyWith(fontSize: 15);
    
    final amountStyle = isTotal
        ? kLabelTextStyle.copyWith(fontSize: 18, color: kPrimaryActionColor)
        : isDiscount
            ? kLabelTextStyle.copyWith(fontSize: 15, color: Colors.green)
            : kLabelTextStyle.copyWith(fontSize: 15);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            isDiscount 
              ? '-RM${(-amount).toStringAsFixed(2)}'
              : 'RM${amount.toStringAsFixed(2)}',
            style: amountStyle,
          ),
        ],
      ),
    );
  }

  // --- ( ✨ NEW WIDGET - This contains the new logic ✨ ) ---
  Widget _buildReviewSection(BuildContext context, OrderModel order) {

    if (order.status.toLowerCase() == 'cancelled') {
      return const SizedBox.shrink();
    }

    if (order.hasBeenReviewed == true && order.rating != null) {
      // Show the review that was left
      return Container(
        width: double.infinity, // Make card full width
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < order.rating! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            if (order.reviewText != null && order.reviewText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  '“${order.reviewText!}”', // Added quotes
                  style: kHintTextStyle.copyWith(fontSize: 15, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      );
    }

    // Show the "Rate This Order" as a text link
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to the new RateOrderPage
              builder: (context) => RateOrderPage(order: order),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8), // Add padding for easier tapping
          child: Text(
            'Rate This Order',
            style: TextStyle(
              color: kPrimaryActionColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline, // Make it look like a link
              decorationColor: kPrimaryActionColor,
            ),
          ),
        ),
      ),
    );
  }
  // --- ( ✨ END NEW WIDGET ✨ ) ---
}