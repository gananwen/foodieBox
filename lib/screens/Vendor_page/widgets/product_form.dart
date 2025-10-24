import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../../../utils/styles.dart';
=======
import '../../../util/styles.dart';
>>>>>>> origin/main

// --- This is a reusable form widget for all the TextFields and Checkboxes ---
// It is used by both add_product_page.dart and modify_product_page.dart

class ProductForm extends StatefulWidget {
  // We pass in controllers and initial values to make it reusable
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController expiryDateController;
  final TextEditingController originalPriceController;
  final TextEditingController discountedPriceController;
  final int initialQuantity;
  final bool isHalal;
  final bool isVegan;
  final bool isNoPork;
  // Callback functions to update the parent page's state
  final Function(int) onQuantityChanged;
  final Function(String, bool) onTagChanged;
  final VoidCallback onUploadImage;

  const ProductForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.expiryDateController,
    required this.originalPriceController,
    required this.discountedPriceController,
    required this.initialQuantity,
    required this.isHalal,
    required this.isVegan,
    required this.isNoPork,
    required this.onQuantityChanged,
    required this.onTagChanged,
    required this.onUploadImage,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  // --- Reusable TextField Builder ---
  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kTextColor)),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Input',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide:
                  const BorderSide(color: kPrimaryActionColor, width: 2),
            ),
          ),
          onChanged: (value) => setState(() {}), // To update suffix icon
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Reusable Tag Checkbox Builder ---
  Widget _buildTagCheckbox(String title, bool value, String key) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(color: kTextColor)),
        value: value,
        onChanged: (bool? newValue) {
          widget.onTagChanged(key, newValue ?? false);
        },
        activeColor: kPrimaryActionColor,
        checkboxShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(widget.titleController, 'Product Title'),
        _buildTextField(widget.descriptionController, 'Product Description'),
        _buildTextField(widget.expiryDateController, 'Expired Date'),
        _buildTextField(widget.originalPriceController, 'Original Price'),
        _buildTextField(widget.discountedPriceController, 'Discounted Price'),

        // --- Upload Image Button ---
        GestureDetector(
          onTap: widget.onUploadImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: kTextColor, size: 30),
                  Text('Upload Product Image',
                      style: TextStyle(color: kTextColor)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- Quantity Counter ---
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                      widget.onQuantityChanged(_quantity);
                    });
                  }
                },
              ),
              Text('$_quantity',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextColor)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    _quantity++;
                    widget.onQuantityChanged(_quantity);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Dietary Tags ---
        const Padding(
          padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text('Dietary Tags',
              style: TextStyle(fontSize: 12, color: kTextColor)),
        ),
        _buildTagCheckbox('Halal', widget.isHalal, 'halal'),
        const SizedBox(height: 8),
        _buildTagCheckbox('Vegan', widget.isVegan, 'vegan'),
        const SizedBox(height: 8),
        _buildTagCheckbox('No Pork', widget.isNoPork, 'noPork'),
      ],
    );
  }
}
