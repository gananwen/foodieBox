import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/util/styles.dart';
import 'product_detail_page.dart';
import 'store_detail_page.dart';

// Helper class to hold vendor and their filtered products
class VendorProductsBundle {
  final VendorModel vendor;
  final List<Product> products;
  VendorProductsBundle({required this.vendor, required this.products});
}

class MainCategoryProductPage extends StatelessWidget {
  final String title;
  final String categoryName;

  const MainCategoryProductPage({
    super.key,
    required this.title,
    required this.categoryName,
  });

  // Function to fetch all products across all vendors for a specific category
  Future<List<VendorProductsBundle>> _fetchCategorizedProducts() async {

    final productsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('products')
        .where('category', isEqualTo: categoryName)
        .where('quantity', isGreaterThan: 0) 
        .get();

    Map<String, List<Product>> groupedProducts = {};
    Set<String> vendorIds = {};

    for (var doc in productsSnapshot.docs) {

      final vendorId = doc.reference.parent.parent!.id; 
      final product = Product.fromMap(doc.data(), doc.id);
      
      vendorIds.add(vendorId);
      
      if (!groupedProducts.containsKey(vendorId)) {
        groupedProducts[vendorId] = [];
      }
      groupedProducts[vendorId]!.add(product);
    }

    if (vendorIds.isEmpty) {
      return [];
    }

    List<VendorModel> vendors = [];

    for (String id in vendorIds) {
      try {
        final vendorDoc = await FirebaseFirestore.instance.collection('vendors').doc(id).get();
        if (vendorDoc.exists) {
          vendors.add(VendorModel.fromMap(vendorDoc.data()!));
        }
      } catch (e) {
        print('Error fetching vendor $id: $e');
      }
    }

    return vendors.map((vendor) {
      return VendorProductsBundle(
        vendor: vendor,
        products: groupedProducts[vendor.uid!] ?? [],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kYellowMedium,
        foregroundColor: kTextColor,
      ),
      body: FutureBuilder<List<VendorProductsBundle>>(
        future: _fetchCategorizedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor),
            );
          }
          if (snapshot.hasError) {
            print('Error in Category Product Fetch: ${snapshot.error}');
            return Center(
              child: Text('Error loading products: ${snapshot.error.toString()}', style: kHintTextStyle),
            );
          }
          
          final bundles = snapshot.data ?? [];
          
          if (bundles.isEmpty) {
            return Center(
              child: Text('No active deals found for "$title".', style: kLabelTextStyle),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0), // For floating button/padding
            itemCount: bundles.length,
            itemBuilder: (context, index) {
              final bundle = bundles[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Vendor Header (Clickable to StoreDetailPage)
                  _buildVendorHeader(context, bundle.vendor),
                  
                  // 2. Products List
                  _buildProductsList(context, bundle.vendor, bundle.products),
                  
                  const SizedBox(height: 10),
                  const Divider(indent: 20, endIndent: 20, height: 1),
                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorHeader(BuildContext context, VendorModel vendor) {
    return GestureDetector(
      onTap: () {
        // Navigate to the full Store Detail Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(vendor: vendor),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: kCardColor,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                vendor.businessPhotoUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.storefront, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.storeName,
                    style: kLabelTextStyle.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor.rating.toStringAsFixed(1)} (${vendor.reviewCount} reviews)',
                        style: kHintTextStyle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: kTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, VendorModel vendor, List<Product> products) {
    return Column(
      children: products.map((product) => _buildProductCard(context, vendor, product)).toList(),
    );
  }

  // Card for the individual product (clickable to ProductDetailPage)
  Widget _buildProductCard(BuildContext context, VendorModel vendor, Product product) {
    return InkWell(
      onTap: () {
        // Navigate to the Product Detail Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              vendor: vendor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 1))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      style: kLabelTextStyle.copyWith(fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    'Exp: ${product.expiryDate}',
                    style: kHintTextStyle.copyWith(fontSize: 13, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'RM${product.discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryActionColor),
                      ),
                      const SizedBox(width: 8),
                      if (product.originalPrice > product.discountedPrice)
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
            // We use an IconButton to signify the user can tap to view/add
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}