import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import 'widgets/product_form.dart'; // Import the reusable form
import 'product_page.dart'; // Import the Product data model

// --- Modify Product Page (Looks like Figure 28, but for Editing) ---
class ModifyProductPage extends StatefulWidget {
  final Product product;
  const ModifyProductPage({super.key, required this.product});

  @override
  State<ModifyProductPage> createState() => _ModifyProductPageState();
}

class _ModifyProductPageState extends State<ModifyProductPage> {
  // Controllers for the form fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _expiryDateController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;

  // State for quantity and tags
  late int _quantity;
  late bool _isHalal;
  late bool _isVegan;
  late bool _isNoPork;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers with the product's data
    _titleController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
        text: 'Dummy Description...'); // Add product.description
    _expiryDateController =
        TextEditingController(text: '10 Oct 2025'); // Add product.expiryDate
    _originalPriceController =
        TextEditingController(text: '4.99'); // Add product.originalPrice
    _discountedPriceController =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));

    // Set initial state from the product
    _quantity = 1; // Add product.quantity
    _isHalal = true; // Add product.isHalal
    _isVegan = true; // Add product.isVegan
    _isNoPork = true; // Add product.isNoPork
  }

  void _onTagChanged(String key, bool value) {
    setState(() {
      switch (key) {
        case 'halal':
          _isHalal = value;
          break;
        case 'vegan':
          _isVegan = value;
          break;
        case 'noPork':
          _isNoPork = value;
          break;
      }
    });
  }

  void _onUploadImage() {
    // TODO: Implement image picking logic
    print('Upload image tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload logic goes here')),
    );
  }

  void _onUpdateProduct() {
    // --- This is where you send updated data to Firebase ---
    print('Updating Product: ${widget.product.id}...');
    print('New Title: ${_titleController.text}');

    // TODO: Add call to Firebase Firestore to update the product document

    // Show a success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product updated successfully!'),
        backgroundColor: kSecondaryAccentColor,
      ),
    );
    // Go back twice: once from this form, once from the preview page
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expiryDateController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title:
            const Text('Modify Product', style: TextStyle(color: kTextColor)),
        backgroundColor: kAppBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // The reusable form, pre-filled with data
            ProductForm(
              titleController: _titleController,
              descriptionController: _descriptionController,
              expiryDateController: _expiryDateController,
              originalPriceController: _originalPriceController,
              discountedPriceController: _discountedPriceController,
              initialQuantity: _quantity,
              isHalal: _isHalal,
              isVegan: _isVegan,
              isNoPork: _isNoPork,
              onQuantityChanged: (qty) => setState(() => _quantity = qty),
              onTagChanged: _onTagChanged,
              onUploadImage: _onUploadImage,
            ),
            const SizedBox(height: 30),

            // --- Update Product Button ---
            ElevatedButton(
              onPressed: _onUpdateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryAccentColor, // E8FFC9
                foregroundColor: kTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Update Product',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
