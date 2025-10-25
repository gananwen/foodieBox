import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 导入 intl package 用于日期格式化
import '../../util/styles.dart'; // 导入你的样式

// --- 添加促销页面 (Figure 33) ---
class AddPromotionPage extends StatefulWidget {
  const AddPromotionPage({super.key});

  @override
  State<AddPromotionPage> createState() => _AddPromotionPageState();
}

class _AddPromotionPageState extends State<AddPromotionPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Form State Variables ---
  String _dealTitle = '';
  String? _selectedProductType; // 'Blindbox', 'Grocery Deal', 'Online Deal'
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double? _originalPrice;
  double? _discountedPrice;
  int _quantity = 1;

  // --- Text Controllers ---
  // 我们用 TextEditingControllers 来显示选中的日期/时间
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void dispose() {
    // 记得 dispose controllers
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // --- 日期选择函数 ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // 使用 intl package 格式化日期
          _startDateController.text = DateFormat('dd MMM yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd MMM yyyy').format(picked);
        }
      });
    }
  }

  // --- 时间选择函数 ---
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = picked.format(context); // 格式化时间
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  // --- 保存表单函数 ---
  void _savePromotion() {
    // 1. 验证表单
    if (_formKey.currentState!.validate()) {
      // 2. 保存表单数据
      _formKey.currentState!.save();

      // 3. TODO: 在这里将数据发送到 Firebase
      print('--- SAVING PROMOTION ---');
      print('Title: $_dealTitle');
      print('Product Type: $_selectedProductType');
      print('Start Date/Time: $_startDate / $_startTime');
      print('End Date/Time: $_endDate / $_endTime');
      print('Price (Orig/Disc): $_originalPrice / $_discountedPrice');
      print('Quantity: $_quantity');

      // 4. 显示成功提示并返回上一页
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash Deal successfully created!'),
          backgroundColor: kSecondaryAccentColor, // 绿色
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // --- (辅助) 可重用的文本输入框 ---
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
            suffixIcon: controller != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.clear(),
                  )
                : null,
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

  // --- (辅助) 可重用的日期/时间输入框 ---
  Widget _buildDateTimePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return _buildTextField(
      label: label,
      onSaved: (value) {}, // 不需要 onSaved，因为我们直接用 controller
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
        title: const Text('Add Flash Deal'),
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
              // --- 1. 上传横幅图片 ---
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
                    border: Border.all(
                        color: kTextColor.withOpacity(0.2), width: 1.5),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: kTextColor),
                        SizedBox(height: 8),
                        Text('Upload Banner Image',
                            style: TextStyle(color: kTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. 促销标题 ---
              _buildTextField(
                label: 'Deal Title',
                onSaved: (value) => _dealTitle = value!,
              ),

              // --- 3. 选择产品类型 ---
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text('Choose Products',
                    style: TextStyle(fontSize: 12, color: kTextColor)),
              ),
              _buildProductTypeRadio('Blindbox'),
              _buildProductTypeRadio('Grocery Deal'),
              _buildProductTypeRadio('Online Deal'),
              const SizedBox(height: 16),

              // --- 4. 开始/结束 时间/日期 ---
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

              // --- 5. 价格 ---
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Original Price',
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
                      onSaved: (value) =>
                          _discountedPrice = double.tryParse(value!),
                      inputType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              // --- 6. 数量 ---
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

              // --- 7. 保存按钮 ---
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
                  onPressed: _savePromotion,
                  child: const Text('Save Deal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (辅助) 构建单选按钮
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
