// 路径: lib/pages/vendor_home/order_review_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import '../../models/order_model.dart'; // 确保 import 路径正确

class OrderReviewDetailsPage extends StatelessWidget {
  final OrderModel order;
  const OrderReviewDetailsPage({super.key, required this.order});

  // (辅助 Widget) 构建星级
  Widget _buildStarRating(double rating, {double size = 24}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (i <= rating) {
        icon = Icons.star;
      } else if (i - 0.5 <= rating) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, color: Colors.amber, size: size));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 6)}...'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Customer Rating',
                style: TextStyle(
                  fontSize: 16,
                  color: kTextColor.withAlpha(180),
                ),
              ),
              const SizedBox(height: 16),
              // 1. 显示星级
              _buildStarRating(order.rating ?? 0, size: 32),
              const SizedBox(height: 8),
              Text(
                '(${order.rating?.toStringAsFixed(1) ?? "N/A"})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const Divider(height: 48, color: kAppBackgroundColor),
              // 2. 显示评价文本
              Text(
                order.reviewText ?? '(No review text provided)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.5, // 行高
                ),
              ),
              const SizedBox(height: 24),
              // 3. 显示日期
              Text(
                order.reviewTimestamp != null
                    ? 'Reviewed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.reviewTimestamp!.toDate())}'
                    : '',
                style: TextStyle(
                  color: kTextColor.withAlpha(150),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
