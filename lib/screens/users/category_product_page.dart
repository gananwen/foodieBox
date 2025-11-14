import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/util/styles.dart';
import 'product_detail_page.dart'; 
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';


class CategoryProductPage extends StatelessWidget {
  final VendorModel vendor;
  final String categoryName;

  const CategoryProductPage({
    super.key,
    required this.vendor,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final productQuery = FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendor.uid) // Ensure vendor.uid is the doc ID
        .collection('products')
        .where('category', isEqualTo: categoryName);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: kYellowMedium,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: kHintTextStyle),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No products found in this category.',
                  style: kHintTextStyle),
            );
          }

          // We have data
          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final product =
                  Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);

              // NEW: Wrap the product row in an InkWell for navigation
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // --- MODIFIED ---
                      // Pass both product and vendor to the detail page
                      builder: (context) => ProductDetailPage(
                        product: product,
                        vendor: vendor,
                      ),
                      // --- END MODIFIED ---
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(product.imageUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              style: kHintTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Price
                            Row(
                              children: [
                                Text(
                                  'RM${product.discountedPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryActionColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (product.originalPrice >
                                    product.discountedPrice)
                                  Text(
                                    'RM${product.originalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // --- MODIFIED: Add to Cart Button ---
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: kPrimaryActionColor, size: 30),
                        onPressed: () {
                          // Get the cart provider (don't listen, just read)
                          final cart = context.read<CartProvider>();
                          // Add 1 of this product
                          cart.addItem(product, vendor, 1);

                          // Show a confirmation snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${product.title} added to cart!'),
                              backgroundColor: kPrimaryActionColor,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      // --- END MODIFICATION ---
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}