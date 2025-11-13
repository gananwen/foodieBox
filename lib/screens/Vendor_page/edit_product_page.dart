import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../models/product.dart'; // 导入 Product 数据模型
import 'modify_product_page.dart'; // 导入编辑表单页
import '../../repositories/product_repository.dart'; // 导入仓库

// --- (已修改) Edit Product Page (Figure 29 - 预览页) ---
class EditProductPage extends StatelessWidget {
  final Product product;
  final int discountPercentage; // <-- 1. 接收折扣
  final ProductRepository _productRepo = ProductRepository();

  EditProductPage({
    super.key,
    required this.product,
    required this.discountPercentage, // <-- 2. 设为必需
  });

  // Helper widget to build a tag
  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kTextColor.withOpacity(0.3)),
      ),
      child:
          Text(label, style: const TextStyle(color: kTextColor, fontSize: 12)),
    );
  }

  // Helper for "Delete" button
  void _deleteProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kPrimaryActionColor),
            child: const Text('Delete'),
            onPressed: () async {
              try {
                await _productRepo.deleteProduct(product.id!);
                if (context.mounted) {
                  Navigator.of(ctx).pop(); // 关闭对话框
                  Navigator.of(context).pop(); // 返回产品列表页
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted'),
                      backgroundColor: kPrimaryActionColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper for "Edit" button
  void _editProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // 注意: 我们只传递 product,
        // modify_product_page 不需要显示折扣
        builder: (context) => ModifyProductPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 3. (新增) 价格计算逻辑 ---
    final bool hasDiscount = discountPercentage > 0;
    final double basePrice =
        product.discountedPrice; // 这是你的 "Discounted Price" 字段
    final double finalPrice = basePrice * (1 - discountPercentage / 100);

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 4. (已修改) 带折扣徽章的图片 ---
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardColor,
                    image: product.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.image_outlined,
                              color: kTextColor, size: 100),
                        )
                      : null,
                ),
                // --- (新增) 折扣徽章 ---
                if (hasDiscount)
                  Positioned(
                    top: 40, // (避开刘海)
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPrimaryActionColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$discountPercentage% OFF',
                        style: const TextStyle(
                          color: kCardColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // --- 内容 ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'No description provided for this product.'
                        : product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 5. (已修改) 价格显示 ---
                  const Text('Price',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  if (hasDiscount) ...[
                    // 有折扣: 显示最终价格 (大)
                    Text(
                      'RM${finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryActionColor, // 粉色
                      ),
                    ),
                    // 显示原价 (划掉) + 百分比
                    Row(
                      children: [
                        Text(
                          'RM${basePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: kTextColor.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($discountPercentage% OFF)',
                          style: const TextStyle(
                            color: kPrimaryActionColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // 无折扣: 只显示原价 (大)
                    Text(
                      'RM${basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: kTextColor, // 正常颜色
                      ),
                    ),
                  ],
                  const SizedBox(height: 35),

                  // --- Expiry Date ---
                  if (product.expiryDate.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPrimaryActionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryActionColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: kPrimaryActionColor, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Expire Date - ${product.expiryDate}',
                            style: const TextStyle(
                                color: kPrimaryActionColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- Dietary Tags ---
                  const Text('Dietary Tags',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (product.isHalal) _buildTag('Halal'),
                      if (product.isVegan) _buildTag('Vegan'),
                      if (product.isNoPork) _buildTag('No Pork'),
                      if (!product.isHalal &&
                          !product.isVegan &&
                          !product.isNoPork)
                        _buildTag('No tags'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- 底部按钮栏 (保持不变) ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _deleteProduct(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryActionColor,
                  side:
                      const BorderSide(color: kPrimaryActionColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _editProduct(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryAccentColor,
                  foregroundColor: kTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
