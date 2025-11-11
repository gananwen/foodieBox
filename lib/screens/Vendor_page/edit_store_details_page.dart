import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'package:flutter/foundation.dart'; // 用于 debugPrint

// --- (完整) 编辑店铺详情 (合并了营业时间) ---
class EditStoreDetailsPage extends StatefulWidget {
  const EditStoreDetailsPage({super.key});

  @override
  State<EditStoreDetailsPage> createState() => _EditStoreDetailsPageState();
}

class _EditStoreDetailsPageState extends State<EditStoreDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _storeNameController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;

  // --- 虚拟数据 (模拟从 Firebase 加载) ---
  final String _currentStoreName = "Afsar's Fresh Mart";
  final String _currentAddress = "123 Jalan Ampang, 50450 Kuala Lumpur";
  final String _currentHours = "9:00 AM - 6:00 PM (Mon-Fri)";

  @override
  void initState() {
    super.initState();
    // 预先填充当前数据
    _storeNameController = TextEditingController(text: _currentStoreName);
    _addressController = TextEditingController(text: _currentAddress);
    _hoursController = TextEditingController(text: _currentHours);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // --- 保存店铺详情 ---
  void _saveStoreDetails() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // TODO: 在这里处理 Firebase 'vendors' 集合的更新

      debugPrint('Store Name: ${_storeNameController.text}');
      debugPrint('Address: ${_addressController.text}');
      debugPrint('Hours: ${_hoursController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store details updated successfully!'),
          backgroundColor: kSecondaryAccentColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // --- (辅助) 可重用的文本输入框 ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hintText,
    int maxLines = 1,
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
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: kCardColor,
            filled: true,
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
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Store Details'),
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
              // --- 店铺详情 ---
              _buildTextField(
                label: 'Store Name',
                controller: _storeNameController,
              ),
              _buildTextField(
                label: 'Store Address',
                controller: _addressController,
                maxLines: 3, // 允许多行输入
              ),

              // --- 营业时间 (合并到这里) ---
              _buildTextField(
                label: 'Store Hours',
                controller: _hoursController,
                hintText: 'e.g., 9:00 AM - 6:00 PM (Mon-Fri)',
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // --- 保存按钮 ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryActionColor, // 高亮色
                    foregroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveStoreDetails,
                  child: const Text('Save Changes',
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
