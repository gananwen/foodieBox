// 路径: lib/pages/vendor_home/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
// --- ( ✨ 关键修复 ✨ ) ---
// 你很可能丢失了下面这两行 import
import '../../models/order_model.dart';
import '../../repositories/analytics_repository.dart'; // <-- 这一行修复了你的错误
import 'order_review_details_page.dart';
// --- ( ✨ 结束修复 ✨ ) ---

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsRepository _repo = AnalyticsRepository(); // <-- 现在这一行不会报错了
  late Stream<List<OrderModel>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = _repo.getVendorReviewsStream();
  }

  // (辅助 Widget) 构建总评分卡
  Widget _buildOverallRatingCard(List<OrderModel> orders) {
    if (orders.isEmpty) {
      // ( ✨ 新增 ✨ ) 如果没有评价，显示一个友好的卡片
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Center(
            child: Text('No reviews yet.',
                style: TextStyle(color: kTextColor, fontSize: 16))),
      );
    }

    // 1. 计算平均分
    double totalRating = 0;
    for (var order in orders) {
      // ( ✨ 修复 ✨ ) 确保只计算有评分的
      if (order.rating != null) {
        totalRating += order.rating!;
      }
    }
    double avgRating = totalRating / orders.length;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: kTextColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Rating',
            style: TextStyle(
              fontSize: 16,
              color: kTextColor.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            avgRating.toStringAsFixed(1), // e.g., "4.7"
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: kPrimaryActionColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildStarRating(avgRating, size: 28),
          const SizedBox(height: 8),
          Text(
            'Based on ${orders.length} reviews',
            style: TextStyle(
              fontSize: 14,
              color: kTextColor.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  // (辅助 Widget) 构建单个订单评价卡
  Widget _buildReviewCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(51), width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        title: Text(
          'Order #${order.id.substring(0, 6)}...',
          style: const TextStyle(
            color: kTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildStarRating(order.rating ?? 0),
            const SizedBox(height: 8),
            Text(
              order.reviewText ?? '(No review text provided)',
              style: TextStyle(color: kTextColor.withAlpha(200), fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderReviewDetailsPage(order: order),
            ),
          );
        },
      ),
    );
  }

  // (辅助 Widget) 构建星级
  Widget _buildStarRating(double rating, {double size = 18}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (i <= rating) {
        icon = Icons.star; // 满星
      } else if (i - 0.5 <= rating) {
        icon = Icons.star_half; // 半星
      } else {
        icon = Icons.star_border; // 空星
      }
      stars.add(Icon(icon, color: Colors.amber, size: size));
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Reviews'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: kPrimaryActionColor)),
            ));
          }

          // ( ✨ 已修改 ✨ ) 即使数据为空，也显示总评分卡
          final List<OrderModel> orders = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 显示总评分 (即使是 0)
                _buildOverallRatingCard(orders),
                const SizedBox(height: 24),

                // 2. 仅当有评价时才显示列表
                if (orders.isNotEmpty) ...[
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. 显示评价列表
                  ListView.builder(
                    itemCount: orders.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(orders[index]);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
