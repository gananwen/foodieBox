// 路径: lib/pages/vendor_home/edit_promotion_page.dart
import 'dart:io'; // <-- ( ✨ 新增 ✨ )
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- ( ✨ 新增 ✨ )
import 'package:intl/intl.dart';
import '../../util/styles.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';

class EditPromotionPage extends StatefulWidget {
  final PromotionModel promotion;
  const EditPromotionPage({super.key, required this.promotion});

  @override
  State<EditPromotionPage> createState() => _EditPromotionPageState();
}

class _EditPromotionPageState extends State<EditPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PromotionRepository();
  bool _isLoading = false;

  // --- ( ✨ 新增状态 ✨ ) ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  late String _existingBannerUrl; // 用于跟踪旧 URL

  late String _dealTitle;
  late String _selectedProductType;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _discountPercentage;
  late int _totalRedemptions;

  late TextEditingController _discountPercController;
  late TextEditingController _totalRedemptionsController;
  late TextEditingController _titleController;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final promo = widget.promotion;

    // ( ✨ 新增 ✨ )
    _existingBannerUrl = promo.bannerUrl;

    _dealTitle = promo.title;
    _selectedProductType = promo.productType;
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    _startTime = TimeOfDay.fromDateTime(promo.startDate);
    _endTime = TimeOfDay.fromDateTime(promo.endDate);
    _discountPercentage = promo.discountPercentage;
    _totalRedemptions = promo.totalRedemptions;

    // ... (不变) 填充 controllers ...
    _titleController = TextEditingController(text: _dealTitle);
    _startDateController.text = DateFormat('dd MMM yyyy').format(_startDate);
    _endDateController.text = DateFormat('dd MMM yyyy').format(_endDate);
    _discountPercController =
        TextEditingController(text: _discountPercentage.toString());
    _totalRedemptionsController =
        TextEditingController(text: _totalRedemptions.toString());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTimeController.text = _startTime.format(context);
        _endTimeController.text = _endTime.format(context);
      }
    });
  }

  @override
  void dispose() {
    // ... (不变)
    super.dispose();
  }

  // ... (日期/时间选择函数 _selectDate, _selectTime 保持不变) ...
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // ... (不变)
  }
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    // ... (不变)
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

  // --- ( ✨ 重大修改：_updatePromotion 函数 ✨ ) ---
  Future<void> _updatePromotion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        String finalBannerUrl = _existingBannerUrl; // 默认为旧 URL

        // 步骤 1: ( ✨ 新增 ✨ ) 检查是否有新图片
        if (_imageFile != null) {
          // 如果有，上传它 (这将覆盖旧图片，因为 promo ID 相同)
          finalBannerUrl =
              await _repo.uploadBannerImage(_imageFile!, widget.promotion.id!);
        }

        // 步骤 2: 组合日期和时间 (不变)
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

        // 步骤 3: 使用 copyWith 创建更新后的模型
        final updatedPromotion = widget.promotion.copyWith(
          title: _dealTitle,
          productType: _selectedProductType,
          startDate: startDateTime,
          endDate: endDateTime,
          discountPercentage: _discountPercentage,
          totalRedemptions: _totalRedemptions,
          bannerUrl: finalBannerUrl, // ( ✨ 使用最终 URL ✨ )
        );

        // 步骤 4: 调用仓库进行更新
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

  Widget _buildDateTimePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    // ... (不变)
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
    // ... (不变)
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
                  child: _buildImageWidget(), // <-- ( ✨ 使用辅助函数 ✨ )
                ),
              ),
              const SizedBox(height: 24),

              // ... (所有其他表单字段保持不变) ...
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
              _buildProductTypeRadio('Grocery'),
              const SizedBox(height: 16),
              // ... (所有其他表单字段保持不变) ...
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

  // --- ( ✨ 新增：辅助函数 ✨ ) ---
  Widget _buildImageWidget() {
    // 1. 如果选择了新图片，显示新图片
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    }
    // 2. 如果有旧图片 URL，显示旧图片
    if (_existingBannerUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _existingBannerUrl,
          fit: BoxFit.cover,
          // (可选) 添加加载和错误处理
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
                child: Icon(Icons.error_outline, color: kPrimaryActionColor));
          },
        ),
      );
    }
    // 3. 否则，显示占位符
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 40, color: kTextColor),
          SizedBox(height: 8),
          Text('Upload New Banner Image', style: TextStyle(color: kTextColor)),
        ],
      ),
    );
  }
}
