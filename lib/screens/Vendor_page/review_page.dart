import 'package:flutter/material.dart';
import '../../util/styles.dart';

// --- 评论页面 (Figure 34) ---
class ReviewPage extends StatelessWidget {
  // 接收从 analytics_page 传过来的产品名称
  final String productName;

  const ReviewPage({super.key, required this.productName});

  // 虚拟数据
  final double overallRating = 4.5;
  final int totalReviews = 120;
  final List<Map<String, dynamic>> ratingBreakdown = const [
    {'stars': 5, 'percent': 0.40, 'label': '40%'},
    {'stars': 4, 'percent': 0.30, 'label': '30%'},
    {'stars': 3, 'percent': 0.15, 'label': '15%'},
    {'stars': 2, 'percent': 0.10, 'label': '10%'},
    {'stars': 1, 'percent': 0.05, 'label': '5%'},
  ];
  final List<Map<String, dynamic>> reviews = const [
    {
      'name': 'Afsar Hossen',
      'date': '2 weeks ago',
      'rating': 5,
      'comment':
          'Love that the blindbox arrive fast and in a good condition!!! Definitely gonna buy more next time.',
      'reply': null,
    },
    {
      'name': 'Sophie Hart',
      'date': '3 days ago',
      'rating': 3,
      'comment':
          'The paper bag didn\'t close properly, but the items still in good condition. The delivery also take more time than it should be...',
      'reply': {
        'name': 'Vendor Name', // 你的名字
        'date': '1 weeks ago',
        'comment':
            'Thank you for your feedback. We will check our new blindboxes while it still in stock!',
      }
    },
  ];

  // --- (辅助) 构建顶部的评分概览 ---
  Widget _buildRatingHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(51), width: 1.5),
      ),
      child: Row(
        children: [
          // 1. 左侧：总评分
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  overallRating.toStringAsFixed(1), // "4.5"
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    // 显示 4 颗实心星和 1 颗空心星
                    return Icon(
                      index < 4 ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalReviews Reviews',
                  style: TextStyle(
                    color: kTextColor.withAlpha(153), // 60%
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // 分隔线
          const VerticalDivider(width: 24),
          // 2. 右侧：评分条
          Expanded(
            flex: 3,
            child: Column(
              children: ratingBreakdown.map((rating) {
                return _buildRatingBar(
                  rating['stars'].toString(),
                  rating['percent'] as double,
                  rating['label'].toString(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- (辅助) 构建单条评分条 (e.g., "5 ★ [====] 40%") ---
  Widget _buildRatingBar(String stars, double percent, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(stars, style: TextStyle(color: kTextColor.withAlpha(153))),
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: kAppBackgroundColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: kTextColor.withAlpha(153), fontSize: 12)),
        ],
      ),
    );
  }

  // --- (辅助) 构建单条客户评论卡片 ---
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(51), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. 客户头像
              CircleAvatar(
                backgroundColor: kSecondaryAccentColor,
                child: const Icon(Icons.person, color: kTextColor),
              ),
              const SizedBox(width: 12),
              // 2. 客户名称和日期
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'],
                      style: const TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      review['date'],
                      style: TextStyle(
                        color: kTextColor.withAlpha(153), // 60%
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 3. 回复按钮
              TextButton(
                onPressed: () {
                  // TODO: 实现回复逻辑
                },
                child: const Text('Reply',
                    style: TextStyle(color: kPrimaryActionColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4. 星星评分
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review['rating'] ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 12),
          // 5. 评论内容
          Text(
            review['comment'],
            style: const TextStyle(color: kTextColor, fontSize: 14),
          ),

          // --- 6. (如果有) 显示商家的回复 ---
          if (review['reply'] != null)
            _buildVendorReply(review['reply'] as Map<String, dynamic>),
        ],
      ),
    );
  }

  // --- (辅助) 构建商家的回复 ---
  Widget _buildVendorReply(Map<String, dynamic> reply) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, left: 24.0), // 缩进
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: kAppBackgroundColor, // 用浅黄色背景
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 回复者 (商家)
          Row(
            children: [
              Text(
                reply['name'],
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reply['date'],
                style: TextStyle(
                  color: kTextColor.withAlpha(153), // 60%
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2. 回复内容
          Text(
            reply['comment'],
            style: const TextStyle(color: kTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: Text('$productName Reviews'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 顶部的总评分卡片
            _buildRatingHeader(),

            // 2. 评论列表
            // 我们用 Column + map 来替代 ListView，因为我们已经在 SingleChildScrollView 里了
            ...reviews.map((review) => _buildReviewCard(review)).toList(),
          ],
        ),
      ),
    );
  }
}
