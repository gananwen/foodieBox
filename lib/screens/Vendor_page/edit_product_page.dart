import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../models/product.dart';
import 'modify_product_page.dart';
import '../../repositories/product_repository.dart';
import 'dart:math' as math; // 用于计算

class EditProductPage extends StatelessWidget {
  final Product product;
  final int discountPercentage; // <-- 1. 接收折扣
  const EditProductPage(
      {super.key, required this.product, this.discountPercentage = 0});

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
                // --- (已修改) 调用 Repository ---
                await ProductRepository().deleteProduct(product.id!);
                if (context.mounted) {
                  Navigator.of(ctx).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back from preview page
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
        builder: (context) => ModifyProductPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // --- 2. (已修改) Product Image ---
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

            // --- 3. (已修改) Content with padding ---
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
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. (已修改) Price Info ---
                  const Text('Price',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  _PriceInfo(
                    originalPrice: product.discountedPrice,
                    discountPercentage: discountPercentage,
                  ),
                  const SizedBox(height: 24),

                  // --- 5. (新增) Category Info ---
                  if (product.category.isNotEmpty) ...[
                    const Text('Category',
                        style: TextStyle(fontSize: 14, color: kTextColor)),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (product.subCategory.isNotEmpty) ...[
                    const Text('Sub-Category',
                        style: TextStyle(fontSize: 14, color: kTextColor)),
                    const SizedBox(height: 4),
                    Text(
                      product.subCategory,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // ---

                  // --- 6. (已修改) Expiry Date ---
                  _ExpiryInfo(date: product.expiryDate),
                  const SizedBox(height: 24),

                  // --- 7. (已修改) Dietary Tags ---
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    borderRadius: BorderRadius.circular(12),
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
                  backgroundColor: kCategoryColor,
                  foregroundColor: kTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  // (辅助) 标签
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
}

// (辅助) 价格 Widget
class _PriceInfo extends StatelessWidget {
  final double originalPrice;
  final int discountPercentage;

  const _PriceInfo(
      {required this.originalPrice, required this.discountPercentage});

  @override
  Widget build(BuildContext context) {
    if (discountPercentage == 0) {
      return Text(
        'RM${originalPrice.toStringAsFixed(2)}',
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      );
    }

    final double discountedPrice =
        originalPrice * (1 - (discountPercentage / 100));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'RM${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            color: kPrimaryActionColor,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'RM${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: kTextColor.withOpacity(0.5),
            fontWeight: FontWeight.normal,
            fontSize: 18,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}

// (辅助) 过期日
class _ExpiryInfo extends StatelessWidget {
  final String date;
  const _ExpiryInfo({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'Expire Date - $date',
            style: const TextStyle(
                color: kPrimaryActionColor,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}
