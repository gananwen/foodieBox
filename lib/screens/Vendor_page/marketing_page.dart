import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import 'add_promotion_page.dart';
import 'analytics_page.dart';
// --- 1. 导入新模型、仓库和编辑页面 ---
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';
import 'edit_promotion_page.dart'; // <-- (新增)

class MarketingPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const MarketingPage({super.key, required this.onBackToDashboard});
  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  // --- 2. 实例化仓库 ---
  final PromotionRepository _repo = PromotionRepository();

  // --- 3. (已修改) 构建促销卡片 ---
  Widget _buildPromotionCard(PromotionModel promo) {
    final bool isActive = promo.startDate.isBefore(DateTime.now()) &&
        promo.endDate.isAfter(DateTime.now());

    final String statusText = isActive
        ? 'Active'
        : (promo.endDate.isBefore(DateTime.now()) ? 'Expired' : 'Scheduled');

    final Color statusColor = isActive
        ? Colors.green
        : (promo.endDate.isBefore(DateTime.now())
            ? kTextColor.withAlpha(100)
            : Colors.blue);

    final String dateRange =
        '${DateFormat('dd MMM').format(promo.startDate)} - ${DateFormat('dd MMM yyyy').format(promo.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? kPrimaryActionColor : kTextColor.withAlpha(51),
          width: isActive ? 2.0 : 1.5,
          color: isActive ? kPrimaryActionColor : kTextColor.withAlpha(51),
          width: isActive ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 横幅图片
          // 1. 横幅图片
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: kAppBackgroundColor.withAlpha(128),
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
                : null,
          ),
          // 2. 详情
          // 2. 详情
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (新增) 状态徽章
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                // (已修改) 使用新字段动态生成描述
                Text(
                  '${promo.discountPercentage}% off all ${promo.productType} products.',
                  '${promo.discountPercentage}% off all ${promo.productType} products.',
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateRange,
                  style: TextStyle(
                    color: kTextColor.withAlpha(179),
                    fontSize: 12,
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
                          color: kTextColor.withAlpha(77), width: 1.5),
                    ),
                    // --- 4. (已修改) 导航到新的 EditPromotionPage ---
                    onPressed: () {
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

  // --- (不变) 构建 Analytics 卡片 ---
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
              stream: _repo.getPromotionsStream(), // (使用已更新的 repo)
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
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active deals found. Tap "+" to create one.',
                        style: TextStyle(color: kTextColor),
                        textAlign: TextAlign.center,
                      ),
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
