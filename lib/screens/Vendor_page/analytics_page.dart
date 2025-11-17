// 路径: lib/pages/vendor_home/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
// --- ( ✨ 1. 更改导入 ✨ ) ---
// 导入 ReviewModel，不再需要 OrderModel 或 OrderReviewDetailsPage
import '../../models/review.dart'; // <-- 导入 review.dart
import '../../repositories/analytics_repository.dart';
// (我们不再需要这个了)
// import 'order_review_details_page.dart';
// --- ( ✨ 结束修改 ✨ ) ---

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsRepository _repo = AnalyticsRepository();
  // --- ( ✨ 2. 更改 Stream 的类型 ✨ ) ---
  late Stream<List<ReviewModel>>
      _reviewsStream; // <-- 从 OrderModel 改为 ReviewModel

  @override
  void initState() {
    super.initState();
    _reviewsStream = _repo.getVendorReviewsStream();
  }

  // --- ( ✨ 3. 修改这个函数以接收 List<ReviewModel> ✨ ) ---
  Widget _buildOverallRatingCard(List<ReviewModel> reviews) {
    // <-- 类型已更改
    if (reviews.isEmpty) {
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
    for (var review in reviews) {
      // <-- 遍历 reviews
      totalRating += review.rating; // <-- 使用 review.rating
    }
    double avgRating = totalRating / reviews.length;

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
            'Based on ${reviews.length} reviews',
            style: TextStyle(
              fontSize: 14,
              color: kTextColor.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  // --- ( ✨ 4. 修改这个函数以接收 ReviewModel ✨ ) ---
  Widget _buildReviewCard(ReviewModel review) {
    // <-- 类型已更改
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
          // ( ✨ 更改: 显示 Order ID )
          'Order #${review.orderId.substring(0, 6)}...', // <-- 使用 review.orderId
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
            _buildStarRating(review.rating), // <-- 使用 review.rating
            const SizedBox(height: 8),
            Text(
              review.reviewText.isEmpty // <-- 使用 review.reviewText
                  ? '(No review text provided)'
                  : review.reviewText,
              style: TextStyle(color: kTextColor.withAlpha(200), fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // ( ✨ 更改: 移除了 onTap 和箭头，因为我们不再需要订单详情 )
        // trailing: const Icon(Icons.chevron_right, color: kTextColor),
        // onTap: () {
        //   (已移除)
        // },
      ),
    );
  }

  // (辅助 Widget) 构建星级 (这个函数不需要修改)
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
      // --- ( ✨ 5. 更改 StreamBuilder 的类型 ✨ ) ---
      body: StreamBuilder<List<ReviewModel>>(
        // <-- 从 OrderModel 改为 ReviewModel
        stream: _reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
            // ( ✨ 提示: 如果你在这里看到 "FAILED_PRECONDITION" 错误, )
            // ( ✨ 那就是 Firebase 在要求你创建新索引 )
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: kPrimaryActionColor)),
            ));
          }

          final List<ReviewModel> reviews = snapshot.data ?? []; // <-- 类型已更改

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallRatingCard(reviews), // <-- 传入 reviews
                const SizedBox(height: 24),

                if (reviews.isNotEmpty) ...[
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    itemCount: reviews.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(reviews[index]); // <-- 传入 review
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
