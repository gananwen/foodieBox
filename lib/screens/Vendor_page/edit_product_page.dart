import 'package:flutter/material.dart';
import '../../util/styles.dart';
// --- (NEW) 导入模型和仓库 ---
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import 'modify_product_page.dart'; // Import the page we are navigating to

// --- Edit Product Page (Figure 29 - The Preview) ---
class EditProductPage extends StatelessWidget {
  final Product product;
  // --- (NEW) ---
  final ProductRepository _productRepo = ProductRepository();

  EditProductPage({super.key, required this.product});

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

  // --- (MODIFIED) Helper for "Delete" button (now async) ---
  void _deleteProduct(BuildContext context) {
    // Show a confirmation dialog
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
              // <-- (MODIFIED) async
              try {
                // --- (MODIFIED) Call to Firebase Repository ---
                await _productRepo.deleteProduct(product.id!);

                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back from preview page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    backgroundColor: kPrimaryActionColor,
                  ),
                );
              } catch (e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper for "Edit" button (no change needed)
  void _editProduct(BuildContext context) {
    // Navigate to the ModifyProductPage, passing the product data
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
            // --- (MODIFIED) Product Image (loads real image) ---
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCardColor,
                border: Border.all(color: kTextColor.withOpacity(0.1)),
              ),
              child: product.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.image_outlined,
                          color: kTextColor, size: 100))
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                            child: Icon(Icons.error,
                                color: kPrimaryActionColor, size: 100));
                      },
                    ),
            ),

            // --- Content with padding ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- (MODIFIED) Product Details (from model) ---
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
                        ? '(No description)'
                        : product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: product.description.isEmpty
                          ? kTextColor.withOpacity(0.5)
                          : kTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- (MODIFIED) Price (from model) ---
                  const Text('Price',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  Row(
                    children: [
                      Text(
                        'RM${product.originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: kTextColor.withOpacity(0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RM${product.discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryActionColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // --- (MODIFIED) Expiry Date (from model) ---
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
                          product.expiryDate.isEmpty
                              ? 'No Expiry Date'
                              : 'Expire Date - ${product.expiryDate}',
                          style: const TextStyle(
                              color: kPrimaryActionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- (MODIFIED) Dietary Tags (from model) ---
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
                        _buildTag('No Tags'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- Bottom Button Bar (no change) ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // --- Delete Button ---
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
            // --- Edit Button ---
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
