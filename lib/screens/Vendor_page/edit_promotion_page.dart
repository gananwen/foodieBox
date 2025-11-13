import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/styles.dart';
// --- 1. 导入新模型和仓库 ---
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';

class EditPromotionPage extends StatefulWidget {
  // --- 2. (已修改) 使用新的 PromotionModel ---
  final PromotionModel promotion;
  const EditPromotionPage({super.key, required this.promotion});

  @override
  State<EditPromotionPage> createState() => _EditPromotionPageState();
}

class _EditPromotionPageState extends State<EditPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PromotionRepository(); // <-- 3. 添加仓库
  bool _isLoading = false;

  // --- 4. (已修改) 更新状态变量 ---
  late String _dealTitle;
  late String _selectedProductType;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _discountPercentage;
  late int _totalRedemptions;

  // (新增) 为新字段添加 Controllers
  late TextEditingController _discountPercController;
  late TextEditingController _totalRedemptionsController;
  late TextEditingController _titleController;

  // (不变)
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // --- 5. (已修改) 预先填充真实数据 ---
    final promo = widget.promotion;
    _dealTitle = promo.title;
    _selectedProductType = promo.productType;
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    _startTime = TimeOfDay.fromDateTime(promo.startDate);
    _endTime = TimeOfDay.fromDateTime(promo.endDate);
    _discountPercentage = promo.discountPercentage;
    _totalRedemptions = promo.totalRedemptions;

    // 填充 controllers
    _titleController = TextEditingController(text: _dealTitle);
    _startDateController.text = DateFormat('dd MMM yyyy').format(_startDate);
    _endDateController.text = DateFormat('dd MMM yyyy').format(_endDate);
    _discountPercController =
        TextEditingController(text: _discountPercentage.toString());
    _totalRedemptionsController =
        TextEditingController(text: _totalRedemptions.toString());

    // 修复: 确保 context 在 format 调用前是可用的
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTimeController.text = _startTime.format(context);
        _endTimeController.text = _endTime.format(context);
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
    _discountPercController.dispose();
    _totalRedemptionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate),
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
      initialTime: (isStartTime ? _startTime : _endTime),
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

  // --- 6. (已修改) _updatePromotion 函数 ---
  Future<void> _updatePromotion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // 组合日期和时间
        final DateTime startDateTime = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        final DateTime endDateTime = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          _endTime.hour,
          _endTime.minute,
        );

        // 使用 copyWith 创建更新后的模型
        final updatedPromotion = widget.promotion.copyWith(
          title: _dealTitle,
          productType: _selectedProductType,
          startDate: startDateTime,
          endDate: endDateTime,
          discountPercentage: _discountPercentage,
          totalRedemptions: _totalRedemptions,
        );

        // 调用仓库进行更新
        await _repo.updatePromotion(updatedPromotion);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flash Deal successfully updated!'),
              backgroundColor: kSecondaryAccentColor,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update deal: $e'),
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

  // --- (辅助) 可重用的文本输入框 (不变) ---
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
                    onPressed: () {
                      controller.clear();
                      // 如果是日期/时间字段，也清除状态
                      if (controller == _startDateController)
                        _startDate = DateTime.now();
                      if (controller == _endDateController)
                        _endDate = DateTime.now();
                      if (controller == _startTimeController)
                        _startTime = TimeOfDay.now();
                      if (controller == _endTimeController)
                        _endTime = TimeOfDay.now();
                    },
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

  // --- (辅助) 可重用的日期/时间输入框 (不变) ---
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
                    // (可选) 加载真实图片
                    // image: widget.promotion.bannerUrl.isNotEmpty
                    //     ? DecorationImage(
                    //         image: NetworkImage(widget.promotion.bannerUrl),
                    //         fit: BoxFit.cover,
                    //       )
                    //     : null,
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
              // --- 7. (已修改) 使用 Controller ---
              _buildTextField(
                label: 'Deal Title',
                controller: _titleController,
                onSaved: (value) => _dealTitle = value!,
              ),
              // --- 8. (已修改) 移除 "Online Deal" ---
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text('Choose Products',
                    style: TextStyle(fontSize: 12, color: kTextColor)),
              ),
              _buildProductTypeRadio('Blindbox'),
              _buildProductTypeRadio('Grocery'),
              const SizedBox(height: 16),
              // --- 9. (不变) 时间/日期 ---
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
              // --- 10. (已修改) 价格 -> 百分比 / 总数 ---
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Discount Percentage (e.g., 20)',
                      controller: _discountPercController,
                      onSaved: (value) =>
                          _discountPercentage = int.tryParse(value!)!,
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
                          _totalRedemptions = int.tryParse(value!)!,
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
              // --- 11. (已修改) 保存按钮 ---
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
                  onPressed: _isLoading ? null : _updatePromotion,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kTextColor))
                      : const Text('Update Deal',
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
          _selectedProductType = value!;
        });
      },
      activeColor: kPrimaryActionColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
