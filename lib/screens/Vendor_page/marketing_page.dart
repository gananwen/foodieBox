import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'add_promotion_page.dart'; // 导入 Add 页面
import 'edit_promotion_page.dart'; // <-- 1. 导入 Edit 页面
import 'analytics_page.dart'; // <-- 2. 导入 Analytics 页面

// --- 促销管理页面 (Figure 32) ---
class MarketingPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const MarketingPage({super.key, required this.onBackToDashboard});
  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  // 用于存放促销活动的虚拟数据
  late Promotion _currentDeal;

  @override
  void initState() {
    super.initState();
    _currentDeal = Promotion(
      id: 'promo1',
      title: 'Summer Sale',
      description: 'Offer 20% off on all summer items',
      expiryDate: DateTime.now().add(const Duration(hours: 24)),
      bannerUrl: '', // 图像URL占位符
    );
  }

  // --- 构建顶部的当前促销卡片 (Flash Deal) ---
  Widget _buildCurrentDealCard(Promotion promo) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimaryActionColor, // 你的高亮色 (Pink)
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 促销横幅图片 (Banner Image)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: kAppBackgroundColor.withAlpha(128), // 50%
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 50, color: kTextColor),
            ),
          ),
          // 2. 促销详情
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expires in 24 hours',
                  style: TextStyle(
                    color: kTextColor.withAlpha(179), // 70%
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo.title,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo.description,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                // "Set up" 或 "Edit" 按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextColor,
                      side: BorderSide(
                          color: kTextColor.withAlpha(77), width: 1.5), // 30%
                    ),
                    onPressed: () {
                      // --- 3. 更新: 跳转到 EditPromotionPage ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPromotionPage(promotion: promo),
                        ),
                      );
                    },
                    child: const Text('Edit Deal'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 构建 Analytics（数据分析）卡片 ---
  Widget _buildAnalyticsCard() {
    return GestureDetector(
      onTap: () {
        // --- 4. 更新: 跳转到 AnalyticsPage ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnalyticsPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: kSecondaryAccentColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: kTextColor.withAlpha(26), // 10%
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ANALYTICS',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: kTextColor.withAlpha(153), // 60%
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Customer Favorites',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'See what products your customers love',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: kTextColor.withAlpha(204), // 80%
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.bar_chart, // 使用数据分析图标
              size: 40.0,
              color: kTextColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Marketing'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: widget.onBackToDashboard,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 当前促销 (Flash Deals) ---
            const Text(
              'Current Deals',
              style: TextStyle(
                color: kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildCurrentDealCard(_currentDeal),

            const SizedBox(height: 24),

            // --- 2. 数据分析 (Analytics) ---
            const Text(
              'Analytics',
              style: TextStyle(
                color: kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildAnalyticsCard(),
          ],
        ),
      ),
      // --- 添加新促销的按钮 ---
      floatingActionButton: FloatingActionButton(
        // --- 修复: 添加 heroTag: null ---
        // 这会禁用 FAB 的 Hero 动画, 避免与下一页冲突
        heroTag: null,
        onPressed: () {
          // 跳转到添加促销页面 (Figure 33)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPromotionPage(),
            ),
          );
        },
        backgroundColor: kSecondaryAccentColor,
        child: const Icon(Icons.add, color: kTextColor),
      ),
    );
  }
}

// --- 促销数据模型 (Promotion Data Model) ---
class Promotion {
  final String id;
  final String title;
  final String description;
  final DateTime expiryDate;
  final String bannerUrl;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.expiryDate,
    required this.bannerUrl,
  });
}
