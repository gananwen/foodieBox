import 'dart:io';
import 'package:flutter/material.dart';
import '../../../util/styles.dart';
// --- (新增) 导入类别数据 ---
import '../../../util/categories.dart';

class ProductForm extends StatefulWidget {
  // We pass in controllers and initial values to make it reusable
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController expiryDateController;
  final TextEditingController originalPriceController;
  final TextEditingController discountedPriceController;

  // Image
  final File? pickedImage;
  final String existingImageUrl;

  // Product Type
  final String productType; // 'Blindbox' or 'Grocery'
  final Function(String) onTypeChanged;

  // --- (新增) Category Fields ---
  final String? selectedCategory;
  final String? selectedSubCategory;
  final Function(String?) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  // ---

  // Quantity and Tags
  final int initialQuantity;
  final bool isHalal;
  final bool isVegan;
  final bool isNoPork;

  // Callback functions
  final Function(int) onQuantityChanged;
  final Function(String, bool) onTagChanged;
  final VoidCallback onUploadImage;
  final VoidCallback? onExpiryDateTap;

  const ProductForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.expiryDateController,
    required this.originalPriceController,
    required this.discountedPriceController,
    this.pickedImage,
    required this.existingImageUrl,
    required this.productType,
    required this.onTypeChanged,
    // --- (新增) ---
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    // ---
    required this.initialQuantity,
    required this.isHalal,
    required this.isVegan,
    required this.isNoPork,
    required this.onQuantityChanged,
    required this.onTagChanged,
    required this.onUploadImage,
    this.onExpiryDateTap,
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

  // --- (不变) Reusable TextField Builder ---
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          fillColor: kCardColor,
          filled: true,
          suffixIcon: (controller.text.isNotEmpty && !readOnly)
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => controller.clear(),
                )
              : (readOnly
                  ? const Icon(Icons.calendar_today_outlined, size: 20)
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withOpacity(0.2)),
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
          return null;
        },
      ),
    );
  }

  // --- (新增) Reusable Dropdown Builder ---
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: kTextColor)),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          fillColor: kCardColor,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryActionColor, width: 2),
          ),
        ),
        dropdownColor: kCardColor, // 下拉菜单背景色
        style: const TextStyle(color: kTextColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  // --- (不变) Reusable Tag Checkbox Builder ---
  Widget _buildTagCheckbox(String title, bool value, String key) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextColor.withOpacity(0.2)),
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
    // --- (新增) 动态获取子类别列表 ---
    final List<String> subCategoryItems = (widget.selectedCategory != null &&
            kGroceryCategories.containsKey(widget.selectedCategory))
        ? kGroceryCategories[widget.selectedCategory]!
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Product Type Selector ---
        const Padding(
          padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text('Product Type',
              style: TextStyle(fontSize: 12, color: kTextColor)),
        ),
        ProductTypeSelector(
          initialType: widget.productType,
          onTypeChanged: widget.onTypeChanged,
        ),
        const SizedBox(height: 16),

        // --- 2. (新增) 动态类别下拉菜单 ---
        if (widget.productType == 'Grocery') ...[
          _buildDropdownField(
            label: 'Category',
            value: widget.selectedCategory,
            items: kGroceryCategories.keys.toList(),
            onChanged: widget.onCategoryChanged,
          ),
          // --- (新增) 动态子类别下拉菜单 ---
          if (widget.selectedCategory != null &&
              widget.selectedCategory!.isNotEmpty) ...[
            _buildDropdownField(
              label: 'Sub-Category',
              value: widget.selectedSubCategory,
              items: subCategoryItems,
              onChanged: widget.onSubCategoryChanged,
            ),
          ]
        ],

        // --- 3. (不变) 文本字段 ---
        _buildTextField(widget.titleController, 'Product Title'),
        _buildTextField(widget.descriptionController, 'Product Description'),
        _buildTextField(
          widget.expiryDateController,
          'Expired Date',
          readOnly: true,
          onTap: widget.onExpiryDateTap,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                widget.originalPriceController,
                'Original Price',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                widget.discountedPriceController,
                'Discounted Price',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),

        // --- 4. (不变) Upload Image Button ---
        GestureDetector(
          onTap: widget.onUploadImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kTextColor.withOpacity(0.2)),
              image: widget.pickedImage != null
                  ? DecorationImage(
                      image: FileImage(widget.pickedImage!), fit: BoxFit.cover)
                  : (widget.existingImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.existingImageUrl),
                          fit: BoxFit.cover)
                      : null),
            ),
            child: (widget.pickedImage == null &&
                    widget.existingImageUrl.isEmpty)
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            color: kTextColor, size: 40),
                        Text('Upload Product Image',
                            style: TextStyle(color: kTextColor)),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // --- 5. (不变) Quantity Counter ---
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: kTextColor, size: 30),
                onPressed: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                      widget.onQuantityChanged(_quantity);
                    });
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('$_quantity',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextColor)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: kTextColor, size: 30),
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

        // --- 6. (不变) Dietary Tags ---
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

// --- (不变) ProductTypeSelector Widget ---
class ProductTypeSelector extends StatelessWidget {
  final String initialType;
  final Function(String) onTypeChanged;

  const ProductTypeSelector({
    super.key,
    required this.initialType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'Blindbox',
          label: Text('Blindbox'),
          icon: Icon(Icons.card_giftcard),
        ),
        ButtonSegment<String>(
          value: 'Grocery',
          label: Text('Grocery'),
          icon: Icon(Icons.shopping_cart),
        ),
      ],
      selected: <String>{initialType},
      onSelectionChanged: (Set<String> newSelection) {
        onTypeChanged(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: kCardColor,
        foregroundColor: kTextColor.withOpacity(0.7),
        selectedForegroundColor: kPrimaryActionColor,
        selectedBackgroundColor: kPrimaryActionColor.withOpacity(0.1),
        side: BorderSide(color: kTextColor.withOpacity(0.2)),
      ),
    );
  }
}
