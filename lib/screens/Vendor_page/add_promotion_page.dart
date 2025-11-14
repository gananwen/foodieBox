// 路径: lib/pages/vendor_home/add_promotion_page.dart
import 'dart:io'; // <-- ( ✨ 新增 ✨ )
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- ( ✨ 新增 ✨ )
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';

class AddPromotionPage extends StatefulWidget {
  const AddPromotionPage({super.key});

  @override
  State<AddPromotionPage> createState() => _AddPromotionPageState();
}

class _AddPromotionPageState extends State<AddPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PromotionRepository();
  bool _isLoading = false;

  // --- ( ✨ 新增状态 ✨ ) ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String _dealTitle = '';
  String? _selectedProductType;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _discountPercentage = 0;
  int _totalRedemptions = 0;

  // ... (所有 controllers 保持不变) ...
  final TextEditingController _discountPercController = TextEditingController();
  final TextEditingController _totalRedemptionsController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void dispose() {
    // ... (不变)
    super.dispose();
  }

  // ... (日期/时间选择函数 _selectDate, _selectTime 保持不变) ...
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

  // --- ( ✨ 新增函数：选择图片 ✨ ) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // --- ( ✨ 重大修改：_savePromotion 函数 ✨ ) ---
  Future<void> _savePromotion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 额外验证
      if (_selectedProductType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a product type'),
              backgroundColor: kPrimaryActionColor),
        );
        return;
      }

      setState(() => _isLoading = true);

      // ( ✨ 修改的逻辑 ✨ )
      String? newPromoId;
      String? bannerUrl;

      try {
        // 步骤 1: 组合日期和时间 (不变)
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

        // 步骤 2: 创建模型 (不带 URL)
        final newPromotion = PromotionModel(
          title: _dealTitle,
          productType: _selectedProductType!,
          startDate: startDateTime,
          endDate: endDateTime,
          discountPercentage: _discountPercentage,
          totalRedemptions: _totalRedemptions,
          bannerUrl: '', // 暂时为空
        );

        // 步骤 3: 保存到 Firestore (现在返回 ID)
        newPromoId = await _repo.addPromotion(newPromotion);

        // 步骤 4: 如果有图片，上传图片
        if (_imageFile != null) {
          bannerUrl = await _repo.uploadBannerImage(_imageFile!, newPromoId);
          // 步骤 5: 更新 Firestore 文档的 bannerUrl
          await _repo.updatePromotionBannerUrl(newPromoId, bannerUrl);
        }

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
        // (错误处理)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to create deal: $e'),
                backgroundColor: kPrimaryActionColor),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ... (_buildTextField, _buildDateTimePicker, _buildProductTypeRadio 保持不变) ...
  Widget _buildTextField({
    required String label,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    // ... (不变)
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
                      if (controller == _startDateController) _startDate = null;
                      if (controller == _endDateController) _endDate = null;
                      if (controller == _startTimeController) _startTime = null;
                      if (controller == _endTimeController) _endTime = null;
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
              // --- 1. ( ✨ 已修改 ✨ ) 上传横幅图片 ---
              GestureDetector(
                onTap: _pickImage, // <-- ( ✨ 绑定函数 ✨ )
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kTextColor.withAlpha(51), width: 1.5),
                  ),
                  // ( ✨ 动态显示 ✨ )
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
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

              // ... (所有其他表单字段保持不变) ...
              _buildTextField(
                label: 'Deal Title',
                onSaved: (value) => _dealTitle = value!,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text('Choose Products',
                    style: TextStyle(fontSize: 12, color: kTextColor)),
              ),
              _buildProductTypeRadio('Blindbox'),
              _buildProductTypeRadio('Grocery'),
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
}
