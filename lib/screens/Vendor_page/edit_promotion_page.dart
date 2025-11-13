import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../util/styles.dart';
import 'marketing_page.dart'; // 导入 Promotion 数据模型
import '../../models/promotion.dart';

// --- 编辑促销页面 ---
class EditPromotionPage extends StatefulWidget {
  final PromotionModel promotion;
  const EditPromotionPage({super.key, required this.promotion});
  @override
  State<EditPromotionPage> createState() => _EditPromotionPageState();
}

class _EditPromotionPageState extends State<EditPromotionPage> {
  final _formKey = GlobalKey<FormState>();

  String _dealTitle = '';
  String? _selectedProductType;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double? _originalPrice;
  double? _discountedPrice;
  int _quantity = 1;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _origPriceController = TextEditingController();
  final TextEditingController _discPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final promo = widget.promotion;

    _dealTitle = promo.title;
    _selectedProductType = promo.productType; // use actual productType
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    _startTime = TimeOfDay.fromDateTime(_startDate!);
    _endTime = TimeOfDay.fromDateTime(_endDate!);
    _originalPrice =
        promo.discountPercentage.toDouble(); // or map to actual price logic
    _discountedPrice = 20.00; // placeholder until you wire pricing
    _quantity = promo.totalRedemptions; // use actual field

    // 填充 controllers (除了时间)
    _titleController.text = _dealTitle;
    _startDateController.text = DateFormat('dd MMM yyyy').format(_startDate!);
    _endDateController.text = DateFormat('dd MMM yyyy').format(_endDate!);
    _origPriceController.text = _originalPrice.toString();
    _discPriceController.text = _discountedPrice.toString();

    // --- 修复: 使用 WidgetsBinding.instance.addPostFrameCallback ---
    // 这能确保 context 在 format 调用前是可用的
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _startTime != null && _endTime != null) {
        // 确保 widget 还在树中且时间不为 null
        _startTimeController.text = _startTime!.format(context);
        _endTimeController.text = _endTime!.format(context);
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _titleController.dispose();
    _origPriceController.dispose();
    _discPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd MMM yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd MMM yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (!context.mounted) return;
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  Future<void> _updatePromotion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: 在这里将更新后的数据发送到 Firebase
      debugPrint('--- UPDATING PROMOTION ---');
      debugPrint('Title: $_dealTitle');
      // ... 打印其他数据
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash Deal successfully updated!'),
          backgroundColor: kSecondaryAccentColor, // 绿色
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildTextField({
    required String label,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
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
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'Input',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: (controller != null && controller.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.clear(),
                  )
                : null,
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
              borderSide:
                  const BorderSide(color: kPrimaryActionColor, width: 2),
            ),
          ),
          keyboardType: inputType,
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a $label';
                }
                return null;
              },
          onSaved: onSaved,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return _buildTextField(
      label: label,
      onSaved: (value) {},
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Flash Deal'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 上传横幅图片 (可以显示已有的图片)
              GestureDetector(
                onTap: () {
                  // TODO: 实现图片上传逻辑
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kTextColor.withAlpha(51), width: 1.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            size: 40, color: kTextColor),
                        const SizedBox(height: 8),
                        const Text('Upload New Banner Image',
                            style: TextStyle(color: kTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Deal Title',
                controller: _titleController,
                onSaved: (value) => _dealTitle = value!,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text('Choose Products',
                    style: TextStyle(fontSize: 12, color: kTextColor)),
              ),
              _buildProductTypeRadio('Blindbox'),
              _buildProductTypeRadio('Grocery Deal'),
              _buildProductTypeRadio('Online Deal'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Start Time',
                      controller: _startTimeController,
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'End Time',
                      controller: _endTimeController,
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'Start Date',
                      controller: _startDateController,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'End Date',
                      controller: _endDateController,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Original Price',
                      controller: _origPriceController,
                      onSaved: (value) =>
                          _originalPrice = double.tryParse(value!),
                      inputType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Discounted Price',
                      controller: _discPriceController,
                      onSaved: (value) =>
                          _discountedPrice = double.tryParse(value!),
                      inputType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Text('$_quantity',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryActionColor, // 你的高亮色
                    foregroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _updatePromotion,
                  child: const Text('Update Deal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTypeRadio(String title) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: kTextColor)),
      value: title,
      groupValue: _selectedProductType,
      onChanged: (String? value) {
        setState(() {
          _selectedProductType = value;
        });
      },
      activeColor: kPrimaryActionColor, // 你的高亮色
      contentPadding: EdgeInsets.zero,
    );
  }
}
