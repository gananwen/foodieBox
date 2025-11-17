import 'dart:io';
import 'package:flutter/material.dart';
import '../../../util/styles.dart';
// --- ( ✨ 新增导入 ✨ ) ---
import '../../../util/categories.dart';

// 这是一个可重用的表单，用于 'add_product_page' 和 'modify_product_page'
class ProductForm extends StatelessWidget {
  // Controllers
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController expiryDateController;
  final TextEditingController originalPriceController;
  final TextEditingController discountedPriceController;

  // Image
  final File? pickedImage;
  final String existingImageUrl;
  final VoidCallback onUploadImage;

  // Type & Category
  final String productType;
  final ValueChanged<String>? onTypeChanged; // ( ✨ 关键 ✨ ) 可为空
  final String? selectedCategory;
  final String? selectedSubCategory;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubCategoryChanged;

  // Quantity
  final int initialQuantity;
  final ValueChanged<int> onQuantityChanged;

  // Tags
  final bool isHalal;
  final bool isVegan;
  final bool isNoPork;
  final Function(String, bool) onTagChanged;

  // Date Picker
  final VoidCallback onExpiryDateTap;

  const ProductForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.expiryDateController,
    required this.originalPriceController,
    required this.discountedPriceController,
    this.pickedImage,
    required this.existingImageUrl,
    required this.onUploadImage,
    required this.productType,
    required this.onTypeChanged, // ( ✨ 关键 ✨ ) 可为空
    this.selectedCategory,
    this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.initialQuantity,
    required this.onQuantityChanged,
    required this.isHalal,
    required this.isVegan,
    required this.isNoPork,
    required this.onTagChanged,
    required this.onExpiryDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // 根据 productType 获取子类别列表
    final List<String> subCategories = (selectedCategory != null &&
            kGroceryCategories.containsKey(selectedCategory))
        ? kGroceryCategories[selectedCategory]!
        : [];

    // ( ✨ 关键逻辑 ✨ )
    // 检查类型选择器是否应该被锁定
    final bool isTypeLocked = (onTypeChanged == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. 图片上传 ---
        _buildImagePicker(
            context, pickedImage, existingImageUrl, onUploadImage),
        const SizedBox(height: 24),

        // --- 2. 产品类型 ---
        _buildSectionTitle('Product Type'),
        // ( ✨ 关键逻辑 ✨ )
        if (isTypeLocked)
          // A. 如果被锁定, 只显示一个 Chip
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(productType),
              backgroundColor: kPrimaryActionColor.withOpacity(0.1),
              labelStyle: const TextStyle(
                  color: kPrimaryActionColor, fontWeight: FontWeight.bold),
              side: BorderSide.none,
            ),
          )
        else
          // B. 否则, 显示 SegmentedButton
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'Blindbox',
                label: Text('Blindbox'),
                icon: Icon(Icons.card_giftcard_outlined),
              ),
              ButtonSegment<String>(
                value: 'Grocery',
                label: Text('Grocery'),
                icon: Icon(Icons.shopping_cart_outlined),
              ),
            ],
            selected: <String>{productType},
            onSelectionChanged: (Set<String> newSelection) {
              onTypeChanged!(newSelection.first); // (我们知道它不为 null)
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: kCardColor,
              foregroundColor: kTextColor.withOpacity(0.7),
              selectedForegroundColor: kPrimaryActionColor,
              selectedBackgroundColor: kPrimaryActionColor.withOpacity(0.1),
              side: BorderSide(color: Colors.grey.withOpacity(0.5)),
            ),
          ),
        const SizedBox(height: 24),

        // --- 3. 详情表单 ---
        _buildSectionTitle('Product Details'),
        _buildTextField(titleController, 'Title', 'e.g., Fresh Apples'),
        _buildTextField(descriptionController, 'Description',
            'Tell us about your product...',
            maxLines: 3),
        _buildTextField(expiryDateController, 'Expiry Date', 'Select date',
            readOnly: true, onTap: onExpiryDateTap, icon: Icons.calendar_today),

        // --- 4. 价格 ---
        _buildSectionTitle('Price (RM)'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                  originalPriceController, 'Original Price', 'e.g., 12.00',
                  inputType: TextInputType.number),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                  discountedPriceController, 'Discounted Price', 'e.g., 9.90',
                  inputType: TextInputType.number),
            ),
          ],
        ),

        // --- 5. 类别 (仅在 'Grocery' 时显示) ---
        if (productType == 'Grocery') ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Category'),
          _buildDropdown(
            'Main Category',
            selectedCategory,
            kGroceryCategories.keys.toList(),
            onCategoryChanged,
          ),
          if (subCategories.isNotEmpty)
            _buildDropdown(
              'Sub-Category',
              selectedSubCategory,
              subCategories,
              onSubCategoryChanged,
            ),
        ],

        // --- 6. 库存 ---
        const SizedBox(height: 16),
        _buildSectionTitle('Stock Quantity'),
        _buildQuantitySelector(initialQuantity, onQuantityChanged),

        // --- 7. 标签 ---
        const SizedBox(height: 16),
        _buildSectionTitle('Tags (Optional)'),
        Wrap(
          spacing: 8.0,
          children: [
            _buildTagChip(
                'Halal', isHalal, (val) => onTagChanged('halal', val)),
            _buildTagChip(
                'Vegan', isVegan, (val) => onTagChanged('vegan', val)),
            _buildTagChip(
                'No Pork', isNoPork, (val) => onTagChanged('noPork', val)),
          ],
        ),
      ],
    );
  }

  // --- 辅助 Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, color: kTextColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, File? pickedImage,
      String existingImageUrl, VoidCallback onUploadImage) {
    ImageProvider? image;
    if (pickedImage != null) {
      image = FileImage(pickedImage);
    } else if (existingImageUrl.isNotEmpty) {
      image = NetworkImage(existingImageUrl);
    }

    return GestureDetector(
      onTap: onUploadImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTextColor.withAlpha(51), width: 1.5),
          image: image != null
              ? DecorationImage(image: image, fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 40, color: kTextColor),
                    SizedBox(height: 8),
                    Text('Upload Product Image',
                        style: TextStyle(color: kTextColor)),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kTextColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: kCardColor, size: 18),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1,
      TextInputType? inputType,
      bool readOnly = false,
      VoidCallback? onTap,
      IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: inputType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          fillColor: kCardColor,
          filled: true,
          suffixIcon:
              icon != null ? Icon(icon, color: kPrimaryActionColor) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withAlpha(51)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withAlpha(51)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryActionColor, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          if (label.contains('Price') && double.tryParse(value) == null) {
            return 'Must be a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(label),
        decoration: InputDecoration(
          fillColor: kCardColor,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withAlpha(51)),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? '$label is required' : null,
      ),
    );
  }

  Widget _buildQuantitySelector(int quantity, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            if (quantity > 1) onChanged(quantity - 1);
          },
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
        ),
        IconButton(
          icon:
              const Icon(Icons.add_circle_outline, color: kPrimaryActionColor),
          onPressed: () {
            onChanged(quantity + 1);
          },
        ),
      ],
    );
  }

  Widget _buildTagChip(
      String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: kCardColor,
      selectedColor: kCategoryColor,
      labelStyle:
          TextStyle(color: isSelected ? kTextColor : kTextColor.withAlpha(179)),
      checkmarkColor: kTextColor,
      side: BorderSide(color: kTextColor.withAlpha(51)),
    );
  }
}
