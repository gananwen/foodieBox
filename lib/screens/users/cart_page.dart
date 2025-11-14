import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/checkout_page.dart';
import 'package:foodiebox/util/styles.dart'; 

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the cart
    final cart = context.watch<CartProvider>();
    final itemsByVendor = cart.itemsByVendor;
    final vendorKeys = itemsByVendor.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(color: kTextColor)),
        backgroundColor: kYellowMedium,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: cart.itemCount == 0
          ? Center(
              // Show a message if the cart is empty
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: kHintTextStyle),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  // List of items, grouped by vendor
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: vendorKeys.length,
                    itemBuilder: (context, index) {
                      final vendorId = vendorKeys[index];
                      final items = itemsByVendor[vendorId]!;
                      final vendorName = items.first.vendorName;
                      final vendorImage = items.first.vendorImage;

                      return _buildVendorGroup(
                          context, cart, vendorName, vendorImage, items);
                    },
                  ),
                ),
                // Bottom summary bar
                _buildOrderSummary(context, cart),
              ],
            ),
    );
  }

  // Builds a card for each vendor
  Widget _buildVendorGroup(BuildContext context, CartProvider cart,
      String vendorName, String vendorImage, List<CartItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    vendorImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Text(vendorName, style: kLabelTextStyle.copyWith(fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // List of items for this vendor
          ...items.map((item) => _buildCartItem(context, cart, item)),
        ],
      ),
    );
  }

  // Builds a row for each item in the cart
  Widget _buildCartItem(BuildContext context, CartProvider cart, CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title,
                    style: kLabelTextStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text('RM${item.product.discountedPrice.toStringAsFixed(2)}',
                    style: kHintTextStyle),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  // Decrease quantity or remove item
                  cart.updateQuantity(item.product.id!, item.quantity - 1);
                },
              ),
              Text(item.quantity.toString(), style: kLabelTextStyle),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: kPrimaryActionColor),
                onPressed: () {
                  // Increase quantity
                  cart.updateQuantity(item.product.id!, item.quantity + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the bottom summary bar with total and checkout button
  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(
          bottom: 30), // Extra padding for safe area (bottom navigation)
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: kLabelTextStyle),
              Text('RM${cart.subtotal.toStringAsFixed(2)}',
                  style: kLabelTextStyle),
            ],
          ),
          // You can add other fees like delivery, discounts here
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: kLabelTextStyle.copyWith(fontSize: 18)),
              Text('RM${cart.subtotal.toStringAsFixed(2)}',
                  style: kLabelTextStyle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Checkout, passing the cart's subtotal and item list
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(
                      subtotal: cart.subtotal,
                      items: cart.itemsList, 
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryActionColor,
                foregroundColor: kTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}