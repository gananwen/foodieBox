import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
// --- 1. 导入新模型和仓库 ---
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';

class AddPromotionPage extends StatefulWidget {
  const AddPromotionPage({super.key});

  @override
  State<AddPromotionPage> createState() => _AddPromotionPageState();
}

class _AddPromotionPageState extends State<AddPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PromotionRepository(); // <-- 2. 添加仓库
  bool _isLoading = false;

  // --- 3. (已修改) 更新状态变量 ---
  String _dealTitle = '';
  String? _selectedProductType; // 'Blindbox' 或 'Grocery'
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _discountPercentage;
  int? _totalRedemptions;

  // (新增) 为新字段添加 Controllers
  final TextEditingController _discountPercController = TextEditingController();
  final TextEditingController _totalRedemptionsController =
      TextEditingController();

  // (不变)
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _discountPercController.dispose();
    _totalRedemptionsController.dispose();
    super.dispose();
  }

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
      initialTime: TimeOfDay.now(),
    );
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

  // --- 4. (已修改) _savePromotion 函数 ---
  Future<void> _savePromotion() async {
    if (_formKey.currentState!.validate()) {
      // 检查自定义字段
      if (_selectedProductType == null ||
          _startDate == null ||
          _endDate == null ||
          _startTime == null ||
          _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all date, time, and type fields.'),
            backgroundColor: kPrimaryActionColor,
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // 组合日期和时间
        final DateTime startDateTime = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        );
        final DateTime endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        // 创建新的 PromotionModel
        final newPromotion = PromotionModel(
          title: _dealTitle,
          productType: _selectedProductType!,
          startDate: startDateTime,
          endDate: endDateTime,
          discountPercentage: _discountPercentage ?? 0,
          totalRedemptions: _totalRedemptions ?? 0,
          // bannerUrl, claimedRedemptions 使用默认值
        );

        // TODO: 在这里添加图片上传逻辑
        // 1. 上传图片到 Storage (如果 _pickedImage != null)
        // 2. 获取 downloadUrl
        // 3. newPromotion.bannerUrl = downloadUrl

        // 保存到 Firebase
        await _repo.addPromotion(newPromotion);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flash Deal successfully created!'),
              backgroundColor: kSecondaryAccentColor,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save deal: $e'),
              backgroundColor: kPrimaryActionColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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

              // --- 3. (已修改) 选择产品类型 ---
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text('Choose Products',
                    style: TextStyle(fontSize: 12, color: kTextColor)),
              ),
              _buildProductTypeRadio('Blindbox'),
              _buildProductTypeRadio('Grocery'), // <-- 移除了 'Deal'
              // 移除了 'Online Deal'
              const SizedBox(height: 16),

              // --- 4. 开始/结束 时间/日期 (不变) ---
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

              // --- 5. (已修改) 价格 -> 百分比 / 总数 ---
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Discount Percentage (e.g., 20)',
                      controller: _discountPercController,
                      onSaved: (value) =>
                          _discountPercentage = int.tryParse(value!),
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final perc = int.tryParse(value);
                        if (perc == null || perc <= 0 || perc > 100) {
                          return '1-100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Total Redemptions (e.g., 100)',
                      controller: _totalRedemptionsController,
                      onSaved: (value) =>
                          _totalRedemptions = int.tryParse(value!),
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- 7. 保存按钮 ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryActionColor,
                    foregroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _savePromotion,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kTextColor))
                      : const Text('Save Deal',
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
      activeColor: kPrimaryActionColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
