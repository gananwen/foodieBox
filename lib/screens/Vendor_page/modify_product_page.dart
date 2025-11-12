import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 导入
import 'package:intl/intl.dart'; // 导入
import '../../util/styles.dart';
import 'widgets/product_form.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class ModifyProductPage extends StatefulWidget {
  final Product product;
  const ModifyProductPage({super.key, required this.product});

  @override
  State<ModifyProductPage> createState() => _ModifyProductPageState();
}

class _ModifyProductPageState extends State<ModifyProductPage> {
  final ProductRepository _productRepo = ProductRepository();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _expiryDateController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;

  late String _productType;
  late int _quantity;
  late bool _isHalal;
  late bool _isVegan;
  late bool _isNoPork;
  File? _pickedImage;
  late String _existingImageUrl; // 存储已存在的 URL

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _expiryDateController =
        TextEditingController(text: widget.product.expiryDate);
    _originalPriceController = TextEditingController(
        text: widget.product.originalPrice.toStringAsFixed(2));
    _discountedPriceController = TextEditingController(
        text: widget.product.discountedPrice.toStringAsFixed(2));

    // Set initial state from the product
    _productType = widget.product.productType;
    _quantity = widget.product.quantity;
    _isHalal = widget.product.isHalal;
    _isVegan = widget.product.isVegan;
    _isNoPork = widget.product.isNoPork;
    _existingImageUrl = widget.product.imageUrl; // 存储旧图片 URL
  }

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

  // --- (不变) 日历功能 ---
  Future<void> _selectExpiryDate() async {
    // 尝试解析已有的日期，如果失败则使用今天
    DateTime initialDate =
        DateFormat('dd MMM yyyy').tryParse(widget.product.expiryDate) ??
            DateTime.now();
    // 确保初始日期不早于 firstDate
    if (initialDate.isBefore(DateTime.now())) {
      initialDate = DateTime.now();
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

  // --- (不变) _onUpdateProduct 函数 ---
  Future<void> _onUpdateProduct() async {
    setState(() => _isLoading = true);
    String newImageUrl = _existingImageUrl; // 默认使用旧图片

    try {
      // 1. 如果有新图片被选中，上传它
      if (_pickedImage != null) {
        newImageUrl = await _productRepo.uploadProductImage(
            _pickedImage!, widget.product.id!);
      }

      // 2. 使用 copyWith 创建更新后的对象
      final updatedProduct = widget.product.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        productType: _productType,
        expiryDate: _expiryDateController.text.trim(),
        originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
        discountedPrice:
            double.tryParse(_discountedPriceController.text) ?? 0.0,
        quantity: _quantity,
        isHalal: _isHalal,
        isVegan: _isVegan,
        isNoPork: _isNoPork,
        imageUrl: newImageUrl, // 使用新 URL 或旧 URL
      );

      // 3. 将其更新到 Firestore
      await _productRepo.updateProduct(updatedProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: kCategoryColor, // (修改) 按钮颜色
          ),
        );
        // 返回产品列表页 (pop 两次)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e')),
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
                existingImageUrl: _existingImageUrl, // 传递旧图片 URL
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
                onPressed: _onUpdateProduct,
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
