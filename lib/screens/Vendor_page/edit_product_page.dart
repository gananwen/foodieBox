import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'product_page.dart'; // Import the Product data model
import 'modify_product_page.dart'; // Import the page we are navigating to

// --- Edit Product Page (Figure 29 - The Preview) ---
class EditProductPage extends StatelessWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

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
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kPrimaryActionColor),
            child: const Text('Delete'),
            onPressed: () {
              // TODO: Add call to Firebase Firestore to delete this product

              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from preview page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted'),
                  backgroundColor: kPrimaryActionColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper for "Edit" button
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
      // --- MODIFIED: Remove AppBar and extend body ---
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        // --- MODIFIED: Custom back button with background ---
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
            // --- Product Image Placeholder (now at the top) ---
            Container(
              height: 300, // Cover upper side
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCardColor,
                border: Border.all(color: kTextColor.withOpacity(0.1)),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: kTextColor, size: 100),
              ),
              // In a real app, you'd use:
              // child: Image.network(product.imageUrl, fit: BoxFit.cover),
            ),

            // --- Content with padding ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Product Details ---
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    // Dummy description, replace with product.description
                    'Apples Are Nutritious. Apples May Be Good For Weight Loss. Apples May Be Good For Your Heart. As Part Of A Healtful And Varied Diet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Price ---
                  const Text('Price',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  Row(
                    children: [
                      Text(
                        'RM4.99', // Dummy original price
                        style: TextStyle(
                          fontSize: 16,
                          color: kTextColor.withOpacity(0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // --- MODIFIED: Highlighted Price ---
                      Text(
                        'RM${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryActionColor, // Highlight color
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // --- Expiry Date ---
                  // --- MODIFIED: Highlighted Expiry Date ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kPrimaryActionColor
                          .withOpacity(0.1), // Light highlight
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimaryActionColor),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: kPrimaryActionColor,
                            size: 18), // Highlight color
                        SizedBox(width: 10),
                        Text(
                          'Expire Date - 10 Oct 2025', // Dummy date
                          style: TextStyle(
                              color: kPrimaryActionColor, // Highlight color
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Dietary Tags ---
                  const Text('Dietary Tags',
                      style: TextStyle(fontSize: 14, color: kTextColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildTag('Halal'),
                      _buildTag('Vegetarian'),
                      _buildTag('No Pork'),
                      // In a real app, you would conditionally show these
                      // based on product.isHalal, etc.
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- Bottom Button Bar ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // --- Delete Button ---
            Expanded(
              child: OutlinedButton(
                onPressed: () => _deleteProduct(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryActionColor, // FFA3AF
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
                  backgroundColor: kSecondaryAccentColor, // E8FFC9
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
