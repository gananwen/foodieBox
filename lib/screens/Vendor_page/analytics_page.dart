import 'package:flutter/material.dart';
import '../../util/styles.dart';

// --- 分析页面 (客户收藏夹) ---
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  // 虚拟数据
  final List<Map<String, String>> favoriteProducts = const [
    {'name': 'Mystery Box', 'sold': '350+ sold', 'rating': '4.8'},
    {'name': 'Fresh Apples', 'sold': '280+ sold', 'rating': '4.5'},
    {'name': 'Fresh Orange', 'sold': '210+ sold', 'rating': '4.6'},
    {'name': 'Fresh Mango', 'sold': '150+ sold', 'rating': '4.7'},
    {'name': 'Fresh Corn', 'sold': '90+ sold', 'rating': '4.3'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer Favorites'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = favoriteProducts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: kTextColor.withAlpha(51), width: 1.5),
            ),
            child: Row(
              children: [
                // 排名
                Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: kPrimaryActionColor, // 高亮色
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                // 产品详情
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']!,
                        style: const TextStyle(
                          color: kTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['sold']!,
                        style: TextStyle(
                          color: kTextColor.withAlpha(179), // 70%
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 评分
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      product['rating']!,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
