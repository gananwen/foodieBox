import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- 1. 导入 intl
import '../../util/styles.dart';
import 'add_promotion_page.dart';
import 'analytics_page.dart';
// --- 2. 导入新模型和仓库 ---
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';
// (移除了旧的 'edit_promotion_page.dart' 导入)

class MarketingPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const MarketingPage({super.key, required this.onBackToDashboard});
  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  // --- 3. 实例化仓库 ---
  final PromotionRepository _repo = PromotionRepository();

  // --- 4. (已修改) 构建促销卡片 ---
  Widget _buildPromotionCard(PromotionModel promo) {
    final bool isActive = promo.endDate.isAfter(DateTime.now());
    final String expiryText = isActive
        ? 'Expires on ${DateFormat('dd MMM yyyy').format(promo.endDate)}'
        : 'Expired on ${DateFormat('dd MMM yyyy').format(promo.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 为卡片添加间距
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? kPrimaryActionColor : kTextColor.withAlpha(51),
          width: isActive ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 横幅图片
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: kAppBackgroundColor.withAlpha(128),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              // (可选) 加载真实图片
              // image: promo.bannerUrl.isNotEmpty
              //     ? DecorationImage(
              //         image: NetworkImage(promo.bannerUrl),
              //         fit: BoxFit.cover,
              //       )
              //     : null,
            ),
            child: promo.bannerUrl.isEmpty
                ? const Center(
                    child:
                        Icon(Icons.image_outlined, size: 50, color: kTextColor))
                : null, // 如果有图片，则不显示图标
          ),
          // 2. 详情
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expiryText,
                  style: TextStyle(
                    color: isActive
                        ? kPrimaryActionColor
                        : kTextColor.withAlpha(179),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
                // (已修改) 使用新字段动态生成描述
                Text(
                  '${promo.discountPercentage}% off all ${promo.productType} products.',
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // (已修改) 显示兑换进度
                Text(
                  'Redemptions: ${promo.claimedRedemptions} / ${promo.totalRedemptions}',
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextColor,
                      side: BorderSide(
                          color: kTextColor.withAlpha(77), width: 1.5),
                    ),
                    onPressed: () {
                      // TODO: 创建一个新的 EditPromotionPage(promo: promo)
                      // (旧的 edit_promotion_page.dart 已失效)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Edit page needs to be updated for new model.')),
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

  // --- (不变) 构建 Analytics 卡片 ---
  Widget _buildAnalyticsCard() {
    return GestureDetector(
      onTap: () {
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
            color: kTextColor.withAlpha(26),
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
              Icons.bar_chart,
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
            // --- 5. (已修改) 使用 StreamBuilder 动态加载促销 ---
            const Text(
              'Current Deals',
              style: TextStyle(
                color: kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<PromotionModel>>(
              stream: _repo.getPromotionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child:
                        CircularProgressIndicator(color: kPrimaryActionColor),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: kPrimaryActionColor)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active deals found. Tap "+" to create one.',
                      style: TextStyle(color: kTextColor),
                    ),
                  );
                }

                // 我们有数据了，构建列表
                final promos = snapshot.data!;
                return ListView.builder(
                  itemCount: promos.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildPromotionCard(promos[index]);
                  },
                );
              },
            ),

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
      // --- (不变) 添加新促销的按钮 ---
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
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
