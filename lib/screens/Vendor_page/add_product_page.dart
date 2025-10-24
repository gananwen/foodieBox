import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'widgets/product_form.dart'; // Import the reusable form

// --- Add Product Page (Figure 28) ---
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // Controllers for the form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  // State for quantity and tags
  int _quantity = 1;
  bool _isHalal = false;
  bool _isVegan = false;
  bool _isNoPork = false;

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
    // TODO: Implement image picking logic (e.g., using image_picker package)
    print('Upload image tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload logic goes here')),
    );
  }

  void _onAddProduct() {
    // --- This is where you send data to Firebase ---
    print('Adding Product...');
    print('Title: ${_titleController.text}');
    print('Description: ${_descriptionController.text}');
    print('Expiry: ${_expiryDateController.text}');
    print('Original Price: ${_originalPriceController.text}');
    print('Discounted Price: ${_discountedPriceController.text}');
    print('Quantity: $_quantity');
    print('Halal: $_isHalal, Vegan: $_isVegan, No Pork: $_isNoPork');

    // TODO: Add call to Firebase Firestore to create the product

    // Show a success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product added successfully!'),
        backgroundColor: kSecondaryAccentColor,
      ),
    );
    Navigator.of(context).pop();
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
            const Text('Add New Product', style: TextStyle(color: kTextColor)),
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
            // The reusable form
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

            // --- Add Product Button ---
            ElevatedButton(
              onPressed: _onAddProduct,
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
                'Add Product',
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
