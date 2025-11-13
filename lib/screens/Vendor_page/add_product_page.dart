import 'dart:io'; // 用于 File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 导入 image_picker
import 'package:intl/intl.dart'; // 导入 intl 用于日期格式化
import '../../util/styles.dart';
import 'widgets/product_form.dart'; // 导入可重用表单
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

// --- Add Product Page (Figure 28) ---
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final ProductRepository _productRepo = ProductRepository();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expiryDateController = TextEditingController(); // Controller 保持不变
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  String _productType = 'Grocery Deal';
  int _quantity = 1;
  bool _isHalal = false;
  bool _isVegan = false;
  bool _isNoPork = false;
  File? _pickedImage;

  // --- NEW: State variables for categories ---
  String? _selectedCategory;
  String? _selectedSubCategory;

  // --- NEW: Category data. You can get this from Firebase later ---
  final Map<String, List<String>> _categoryMap = {
    'Frozen': ['All', 'Frozen Meals', 'Ice Cream', 'Frozen Puff & Pastry'],
    'Baked Goods': ['All', 'Bread', 'Cakes'],
    'Vegetables': ['All', 'Leafy Greens', 'Root Vegetables'],
    'Spice': ['All', 'Herbs', 'Ground Spices'],
    'Beverages': ['All', 'Soft Drinks', 'Juice', 'Coffee & Tea'],
    'Non-Halal Food': ['All', 'Pork', 'Alcoholic Beverages'],
  };
  List<String> _subCategories = [];
  // --- END NEW ---

  void _onTypeChanged(String type) {
    setState(() {
      _productType = type;
    });
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

  Future<void> _onUploadImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryActionColor,
              onPrimary: kCardColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryActionColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);
      setState(() {
        _expiryDateController.text = formattedDate;
      });
    }
  }

  // --- MODIFIED: _onAddProduct function ---
  Future<void> _onAddProduct() async {
    if (_titleController.text.isEmpty ||
        _discountedPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in Title and Discounted Price.')),
      );
      return;
    }
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }
    // --- NEW: Category validation ---
    if (_selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Category and Sub-Category.')),
      );
      return;
    }
    // --- END NEW ---

    setState(() => _isLoading = true);
    try {
      // --- MODIFIED: Added category and subCategory ---
      final product = Product(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        productType: _productType,
        category: _selectedCategory!,     // NEW
        subCategory: _selectedSubCategory!, // NEW
        expiryDate: _expiryDateController.text.trim(),
        originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
        discountedPrice:
            double.tryParse(_discountedPriceController.text) ?? 0.0,
        imageUrl: '',
        quantity: _quantity,
        isHalal: _isHalal,
        isVegan: _isVegan,
        isNoPork: _isNoPork,
      );
      // --- END MODIFIED ---

      DocumentReference<Product> newDocRef =
          await _productRepo.addProduct(product);
      String imageUrl =
          await _productRepo.uploadProductImage(_pickedImage!, newDocRef.id);
      await _productRepo.updateProduct(
          product.copyWith(id: newDocRef.id, imageUrl: imageUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: kCategoryColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  // --- NEW: Helper widget for dropdowns ---
  Widget _buildDropdown(
      {required String hint,
      required String? value,
      required List<String> items,
      required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: kHintTextStyle),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(color: kTextColor)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(
                    child:
                        CircularProgressIndicator(color: kPrimaryActionColor)),
              )
            else
              // --- MODIFIED: Added Column for new dropdowns ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- NEW: Category Dropdown ---
                  const Text('Category', style: kLabelTextStyle),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'Select Category',
                    value: _selectedCategory,
                    items: _categoryMap.keys.toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _selectedSubCategory = null; // Reset sub-category
                        _subCategories = _categoryMap[newValue] ?? [];
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- NEW: Sub-Category Dropdown ---
                  const Text('Sub-Category', style: kLabelTextStyle),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'Select Sub-Category',
                    value: _selectedSubCategory,
                    items: _subCategories,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // This is your original ProductForm
                  ProductForm(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    expiryDateController: _expiryDateController,
                    originalPriceController: _originalPriceController,
                    discountedPriceController: _discountedPriceController,
                    productType: _productType,
                    initialQuantity: _quantity,
                    isHalal: _isHalal,
                    isVegan: _isVegan,
                    isNoPork: _isNoPork,
                    pickedImage: _pickedImage,
                    existingImageUrl: null,
                    onQuantityChanged: (qty) => setState(() => _quantity = qty),
                    onTagChanged: _onTagChanged,
                    onTypeChanged: _onTypeChanged,
                    onUploadImage: _onUploadImage,
                    onExpiryDateTap: _selectExpiryDate, // 日历功能
                  ),
                ],
              ),
            const SizedBox(height: 30),
            if (!_isLoading)
              ElevatedButton(
                onPressed: _onAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCategoryColor, // 深绿色
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