import 'dart:io'; // 用于 File
import 'package:flutter/material.dart';
import '../../../util/styles.dart';

class ProductForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController expiryDateController;
  final TextEditingController originalPriceController;
  final TextEditingController discountedPriceController;
  final String productType;
  final int initialQuantity;
  final bool isHalal;
  final bool isVegan;
  final bool isNoPork;
  final File? pickedImage;
  final String? existingImageUrl;
  final Function(int) onQuantityChanged;
  final Function(String, bool) onTagChanged;
  final Function(String) onTypeChanged;
  final VoidCallback onUploadImage;
  final VoidCallback? onExpiryDateTap;

  const ProductForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.expiryDateController,
    required this.originalPriceController,
    required this.discountedPriceController,
    required this.productType,
    required this.initialQuantity,
    required this.isHalal,
    required this.isVegan,
    required this.isNoPork,
    this.pickedImage,
    this.existingImageUrl,
    required this.onQuantityChanged,
    required this.onTagChanged,
    required this.onTypeChanged,
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

  // --- (辅助) 可重用的文本输入框 ---
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
              // --- (修改) 样式 1 ---
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              // --- (修改) 样式 2 ---
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              // --- (修改) 样式 3 ---
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: kPrimaryActionColor, width: 2),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- (辅助) 可重用的日期选择框 ---
  Widget _buildDatePickerField(
    TextEditingController controller,
    String label,
    VoidCallback? onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kTextColor)),
        ),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select date...',
                fillColor: kCardColor,
                filled: true,
                suffixIcon: const Icon(Icons.calendar_month_outlined,
                    color: kPrimaryActionColor),
                border: OutlineInputBorder(
                  // --- (修改) 样式 4 ---
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  // --- (修改) 样式 5 ---
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  // --- (修改) 样式 6 ---
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: kPrimaryActionColor, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- (辅助) 可重用的标签复选框 ---
  Widget _buildTagCheckbox(String title, bool value, String key) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        // --- (修改) 样式 7 ---
        borderRadius: BorderRadius.circular(12),
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

  // --- (辅助) 上传图片框 ---
  Widget _buildImagePicker() {
    // (这个 widget 已经在使用 borderRadius 12 了，所以不用改)
    if (widget.pickedImage != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.pickedImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          GestureDetector(
            onTap: widget.onUploadImage,
            child: const Text('Image Selected (Tap to change)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (widget.existingImageUrl != null &&
        widget.existingImageUrl!.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.existingImageUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          GestureDetector(
            onTap: widget.onUploadImage,
            child: const Text('Tap to change image',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    return GestureDetector(
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
              Icon(Icons.cloud_upload_outlined, color: kTextColor, size: 30),
              Text('Upload Product Image', style: TextStyle(color: kTextColor)),
            ],
          ),
        ),
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

        const Padding(
          padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text('Product Type',
              style: TextStyle(fontSize: 12, color: kTextColor)),
        ),
        ProductTypeSelector(
          selectedType: widget.productType,
          onTypeChanged: widget.onTypeChanged,
        ),
        const SizedBox(height: 16),

        _buildDatePickerField(
          widget.expiryDateController,
          'Expired Date',
          widget.onExpiryDateTap,
        ),

        _buildTextField(widget.originalPriceController, 'Original Price'),
        _buildTextField(widget.discountedPriceController, 'Discounted Price'),

        _buildImagePicker(),
        const SizedBox(height: 20),

        // --- 数量选择器 ---
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

        // --- 标签 ---
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

// --- (辅助) 产品类型选择器 ---
class ProductTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const ProductTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'Blind Box',
          label: Text('Blind Box'),
          icon: Icon(Icons.card_giftcard_outlined),
        ),
        ButtonSegment<String>(
          value: 'Grocery Deal',
          label: Text('Grocery Deal'),
          icon: Icon(Icons.shopping_cart_outlined),
        ),
      ],
      selected: <String>{selectedType},
      onSelectionChanged: (Set<String> newSelection) {
        onTypeChanged(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: kCardColor,
        foregroundColor: kTextColor.withOpacity(0.7),
        selectedForegroundColor: kPrimaryActionColor,
        selectedBackgroundColor: kPrimaryActionColor.withOpacity(0.1),
        // (这个样式已经匹配了)
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }
}
