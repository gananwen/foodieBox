import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import 'widgets/product_form.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
// --- (新增) 导入类别数据 ---
import '../../util/categories.dart';

class ModifyProductPage extends StatefulWidget {
  final Product product;
  const ModifyProductPage({super.key, required this.product});

  @override
  State<ModifyProductPage> createState() => _ModifyProductPageState();
}

class _ModifyProductPageState extends State<ModifyProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _expiryDateController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;

  // State
  File? _pickedImage;
  late String _productType;
  late int _quantity;
  late bool _isHalal;
  late bool _isVegan;
  late bool _isNoPork;
  late String _existingImageUrl;

  // --- (新增) Category State ---
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _subCategories = [];
  // ---

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product.title);
    _descriptionController = TextEditingController(text: product.description);
    _expiryDateController = TextEditingController(text: product.expiryDate);
    _originalPriceController =
        TextEditingController(text: product.originalPrice.toStringAsFixed(2));
    _discountedPriceController =
        TextEditingController(text: product.discountedPrice.toStringAsFixed(2));
    _existingImageUrl = product.imageUrl;
    _productType = product.productType;
    _quantity = product.quantity;
    _isHalal = product.isHalal;
    _isVegan = product.isVegan;
    _isNoPork = product.isNoPork;

    // --- (新增) 加载类别 ---
    if (product.category.isNotEmpty) {
      _selectedCategory = product.category;
      _subCategories = kGroceryCategories[product.category] ?? [];
      if (product.subCategory.isNotEmpty) {
        _selectedSubCategory = product.subCategory;
      }
    }
    // ---
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

  // --- (新增) Category Handlers ---
  void _onTypeChanged(String type) {
    setState(() {
      _productType = type;
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
      initialDate:
          DateFormat('dd MMM yyyy').tryParse(_expiryDateController.text) ??
              DateTime.now(),
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

  Future<void> _onUpdateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- (新增) 类别验证 ---
    String finalCategory;
    String finalSubCategory;

    if (_productType == 'Blindbox') {
      finalCategory = 'Hot Deals';
      finalSubCategory = '';
    } else {
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

    setState(() => _isLoading = true);

    try {
      String newImageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        newImageUrl = await _productRepo.uploadProductImage(
            _pickedImage!, widget.product.id!);
      }

      final updatedProduct = widget.product.copyWith(
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
        imageUrl: newImageUrl,
        quantity: _quantity,
        isHalal: _isHalal,
        isVegan: _isVegan,
        isNoPork: _isNoPork,
      );

      await _productRepo.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: kSecondaryAccentColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update product: $e'),
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
                  existingImageUrl: _existingImageUrl,
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
                  onPressed: _onUpdateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCategoryColor,
                    foregroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}
