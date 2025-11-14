import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../util/styles.dart';
import 'widgets/product_form.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
// --- (新增) 导入类别数据 ---
import '../../util/categories.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository();
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  // State
  File? _pickedImage;
  String _productType = 'Grocery'; // 默认
  int _quantity = 1;
  bool _isHalal = false;
  bool _isVegan = false;
  bool _isNoPork = false;

  // --- (新增) Category State ---
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _subCategories = [];
  // ---

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expiryDateController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  // --- (新增) Category Handlers ---
  void _onTypeChanged(String type) {
    setState(() {
      _productType = type;
      // 重置类别
      _selectedCategory = null;
      _selectedSubCategory = null;
      _subCategories = [];
    });
  }

  void _onCategoryChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedCategory = newValue;
      _selectedSubCategory = null; // 重置子类别
      _subCategories = kGroceryCategories[newValue] ?? [];
    });
  }

  void _onSubCategoryChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedSubCategory = newValue;
    });
  }
  // ---

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
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
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

  Future<void> _onAddProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- (新增) 类别验证 ---
    String finalCategory;
    String finalSubCategory;

    if (_productType == 'Blindbox') {
      finalCategory = 'Hot Deals'; // 自动设置
      finalSubCategory = '';
    } else {
      // Grocery 验证
      if (_selectedCategory == null || _selectedSubCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category and sub-category.'),
            backgroundColor: kPrimaryActionColor,
          ),
        );
        return;
      }
      finalCategory = _selectedCategory!;
      finalSubCategory = _selectedSubCategory!;
    }
    // ---

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload an image.'),
            backgroundColor: kPrimaryActionColor),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = Product(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        productType: _productType,
        // --- (新增) 保存类别 ---
        category: finalCategory,
        subCategory: finalSubCategory,
        // ---
        expiryDate: _expiryDateController.text.trim(),
        originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
        discountedPrice:
            double.tryParse(_discountedPriceController.text) ?? 0.0,
        imageUrl: '', // 暂时为空
        quantity: _quantity,
        isHalal: _isHalal,
        isVegan: _isVegan,
        isNoPork: _isNoPork,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add product: $e'),
              backgroundColor: kPrimaryActionColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: kPrimaryActionColor),
                )
              else
                ProductForm(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  expiryDateController: _expiryDateController,
                  originalPriceController: _originalPriceController,
                  discountedPriceController: _discountedPriceController,
                  pickedImage: _pickedImage,
                  existingImageUrl: '',
                  productType: _productType,
                  onTypeChanged: _onTypeChanged,
                  // --- (新增) 传递类别 ---
                  selectedCategory: _selectedCategory,
                  selectedSubCategory: _selectedSubCategory,
                  onCategoryChanged: _onCategoryChanged,
                  onSubCategoryChanged: _onSubCategoryChanged,
                  // ---
                  initialQuantity: _quantity,
                  isHalal: _isHalal,
                  isVegan: _isVegan,
                  isNoPork: _isNoPork,
                  onQuantityChanged: (qty) => setState(() => _quantity = qty),
                  onTagChanged: _onTagChanged,
                  onUploadImage: _onUploadImage,
                  onExpiryDateTap: _selectExpiryDate,
                ),
              const SizedBox(height: 30),
              if (!_isLoading)
                ElevatedButton(
                  onPressed: _onAddProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCategoryColor,
                    foregroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}
