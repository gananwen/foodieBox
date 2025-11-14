// 路径: lib/pages/vendor_home/marketing_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import 'add_promotion_page.dart';
import 'analytics_page.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';
import 'edit_promotion_page.dart';

class MarketingPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const MarketingPage({super.key, required this.onBackToDashboard});
  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  final PromotionRepository _repo = PromotionRepository();

  Widget _buildPromotionCard(PromotionModel promo) {
    // ... (状态和日期逻辑不变) ...
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
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. ( ✨ 已修改 ✨ ) 横幅图片 ---
          Container(
            height: 120,
            width: double.infinity, // 确保容器填满宽度
            decoration: BoxDecoration(
              color: kAppBackgroundColor.withAlpha(128),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            // ( ✨ 动态显示 ✨ )
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: promo.bannerUrl.isEmpty
                  // A. 如果没有 URL，显示占位符
                  ? const Center(
                      child: Icon(Icons.image_outlined,
                          size: 50, color: kTextColor),
                    )
                  // B. 如果有 URL，显示网络图片
                  : Image.network(
                      promo.bannerUrl,
                      fit: BoxFit.cover,
                      // (可选) 添加加载和错误处理
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: kPrimaryActionColor, strokeWidth: 2.0));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                            child: Icon(Icons.error_outline,
                                color: kPrimaryActionColor));
                      },
                    ),
            ),
          ),

          // 2. 详情 (不变)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (状态徽章) ...
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
                // ... (所有其他详情不变) ...
                const SizedBox(height: 4),
                Text(
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

  // ... (_buildAnalyticsCard, build, StreamBuilder 保持不变) ...
  Widget _buildAnalyticsCard() {
    // ... (不变)
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
    // ... (不变)
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
