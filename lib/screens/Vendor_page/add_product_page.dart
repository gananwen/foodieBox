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

  // --- (修改) 改回 ImageSource.gallery ---
  Future<void> _onUploadImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery, // <-- 从 .camera 改回 .gallery
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

  // --- (不变) 显示日期选择器的函数 ---
  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // 只能选今天或之后的日期
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

  // --- (不变) _onAddProduct 函数 ---
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
    setState(() => _isLoading = true);
    try {
      final product = Product(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        productType: _productType,
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
              // --- (不变) ProductForm 调用 ---
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
            const SizedBox(height: 30),
            if (!_isLoading)
              // --- (不变) 按钮 ---
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
