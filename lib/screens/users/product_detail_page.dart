import 'package:flutter/material.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/util/styles.dart';

// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/providers/cart_provider.dart';
// --- END NEW IMPORTS ---

class ProductDetailPage extends StatefulWidget {
  final Product product;
  // --- MODIFICATION: Vendor is required to add to cart ---
  final VendorModel vendor;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.vendor, // Added vendor
  });
  // --- END MODIFICATION ---

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    // Calculate prices based on quantity
    double currentPrice = widget.product.discountedPrice * _quantity;
    double originalPrice = widget.product.originalPrice * _quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: kTextColor),
            onPressed: () {
              // TODO: Handle share action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Product Image ---
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kCardColor, // Or Colors.grey[200]
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(widget.product.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Title and Favorite ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.product.title,
                      style: kLabelTextStyle.copyWith(fontSize: 24),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border,
                        color: kTextColor, size: 28),
                    onPressed: () {
                      // TODO: Handle favorite action
                    },
                  ),
                ],
              ),
              Text(
                '${widget.product.category} | ${widget.product.subCategory}',
                style: kHintTextStyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // --- Quantity and Price ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove,
                              size: 20, color: kTextColor),
                          onPressed: () {
                            setState(() {
                              if (_quantity > 1) _quantity--;
                            });
                          },
                        ),
                        Text(
                          _quantity.toString(),
                          style: kLabelTextStyle.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add,
                              size: 20, color: kTextColor),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'NOW',
                        style: kHintTextStyle.copyWith(fontSize: 12),
                      ),
                      Row(
                        children: [
                          Text(
                            'RM${currentPrice.toStringAsFixed(2)}',
                            style: kLabelTextStyle.copyWith(
                                fontSize: 22, color: kPrimaryActionColor),
                          ),
                          if (originalPrice > currentPrice) ...[
                            const SizedBox(width: 8),
                            Text(
                              'RM${originalPrice.toStringAsFixed(2)}',
                              style: kHintTextStyle.copyWith(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Expiry Date ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.orange[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Expire Date - ${widget.product.expiryDate}', // Assuming expiryDate is a formatted string
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Product Detail ---
              Text('Product Detail',
                  style: kLabelTextStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                widget.product.description,
                style: kHintTextStyle.copyWith(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),

              // --- Nutritions (Placeholder) ---
              // NOTE: This data is not in your product.dart model.
              // You will need to add fields to your model and Firebase to populate this.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nutritions',
                      style: kLabelTextStyle.copyWith(fontSize: 18)),
                  Row(
                    children: [
                      Text('100gr', style: kHintTextStyle),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Calories: 52 kcal', style: kHintTextStyle),
                    Text('Protein: 0.3g', style: kHintTextStyle),
                    Text('Carbs: 14g', style: kHintTextStyle),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Review (Placeholder) ---
              // NOTE: This data is not in your product.dart model.
              Text('Review', style: kLabelTextStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: kYellowMedium, size: 20),
                  const Icon(Icons.star, color: kYellowMedium, size: 20),
                  const Icon(Icons.star, color: kYellowMedium, size: 20),
                  const Icon(Icons.star, color: kYellowMedium, size: 20),
                  Icon(Icons.star, color: Colors.grey[300], size: 20),
                  const SizedBox(width: 8),
                  const Text('4.0 (128 reviews)', style: kHintTextStyle)
                ],
              ),
              const SizedBox(height: 30), // Spacing before button
            ],
          ),
        ),
      ),
      // --- Bottom Add to Cart Button ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: ElevatedButton(
          // --- MODIFICATION: Add to cart logic ---
          onPressed: () {
            // 1. Get the cart provider
            final cart = context.read<CartProvider>();
            
            // 2. Add the item with the correct vendor and quantity
            cart.addItem(widget.product, widget.vendor, _quantity);

            // 3. Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Added $_quantity x ${widget.product.title} to cart!'),
                backgroundColor: kPrimaryActionColor, // Use your theme color
                duration: const Duration(seconds: 2),
              ),
            );

            // 4. Go back to the previous screen
            Navigator.of(context).pop();
          },
          // --- END MODIFICATION ---
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryActionColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add to Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Assuming you want white text on primary color
            ),
          ),
        ),
      ),
    );
  }
}