import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/checkout_page.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:foodiebox/screens/users/pickup_payment_page.dart';
// Import the enum
import 'package:foodiebox/enums/checkout_type.dart'; 

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // --- NO MORE _selectedOption state ---

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final itemsByVendor = cart.itemsByVendor;
    final vendorKeys = itemsByVendor.keys.toList();

    // --- Read the selected option from the provider ---
    final selectedOption = cart.selectedCheckoutType;
    // ---

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(color: kTextColor)),
        backgroundColor: kYellowMedium,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: cart.itemCount == 0
          ? Center(
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
                // --- Pass the selected option to the summary ---
                _buildOrderSummary(context, cart, selectedOption),
              ],
            ),
    );
  }

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
          ...items.map((item) => _buildCartItem(context, cart, item)),
        ],
      ),
    );
  }

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
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  cart.updateQuantity(item.product.id!, item.quantity - 1);
                },
              ),
              Text(item.quantity.toString(), style: kLabelTextStyle),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: kPrimaryActionColor),
                onPressed: () {
                  cart.updateQuantity(item.product.id!, item.quantity + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- _buildToggleButton REMOVED ---
  // We no longer need this widget here as it's redundant.

  Widget _buildOrderSummary(BuildContext context, CartProvider cart,
      CheckoutType selectedOption) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- NEW: Display-only widget for order mode ---
          const Text('Your Order Details', style: kLabelTextStyle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      selectedOption == CheckoutType.delivery
                          ? Icons.delivery_dining
                          : Icons.store,
                      color: kPrimaryActionColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Order Mode: ',
                      style: kLabelTextStyle.copyWith(fontSize: 16),
                    ),
                    Text(
                      selectedOption == CheckoutType.delivery
                          ? 'Delivery'
                          : 'Pickup',
                      style: kLabelTextStyle.copyWith(
                          fontSize: 16, color: kPrimaryActionColor),
                    ),
                  ],
                ),
                // If it's pickup, also show the time
                if (selectedOption == CheckoutType.pickup &&
                    cart.selectedPickupDay != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: kPrimaryActionColor),
                        const SizedBox(width: 12),
                        Text(
                          'Pickup Time: ',
                          style: kLabelTextStyle.copyWith(fontSize: 16),
                        ),
                        Expanded(
                          child: Text(
                            '${cart.selectedPickupDay}, ${cart.selectedPickupTime}',
                            style: kLabelTextStyle.copyWith(
                                fontSize: 16, color: kPrimaryActionColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // --- END NEW ---

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: kLabelTextStyle),
              Text('RM${cart.subtotal.toStringAsFixed(2)}',
                  style: kLabelTextStyle),
            ],
          ),
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
                if (selectedOption == CheckoutType.delivery) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        subtotal: cart.subtotal,
                        items: cart.itemsList,
                      ),
                    ),
                  );
                } else {
                  // This logic is still correct.
                  if (cart.selectedPickupDay == null ||
                      cart.selectedPickupTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a pickup time from the store page first.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PickupPaymentPage(
                        subtotal: cart.subtotal,
                        items: cart.itemsList,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryActionColor,
                foregroundColor: kTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                // This text also updates correctly based on the provider
                selectedOption == CheckoutType.delivery
                    ? 'Proceed to Checkout'
                    : 'Proceed to Pickup Payment',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}