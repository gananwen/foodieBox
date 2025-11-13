import 'package:flutter/material.dart';
import '../../util/styles.dart';
// 导入 Repository 和 Models
import '../../repositories/vendor_data_repository.dart';

class EditStoreDetailsPage extends StatefulWidget {
  final VendorDataBundle bundle; // 接收数据
  const EditStoreDetailsPage({super.key, required this.bundle});

  @override
  State<EditStoreDetailsPage> createState() => _EditStoreDetailsPageState();
}

class _EditStoreDetailsPageState extends State<EditStoreDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = VendorDataRepository();
  bool _isLoading = false;

  // --- Controllers ---
  late TextEditingController _storeNameController;
  late TextEditingController _addressController;
  late String _vendorType;

  @override
  void initState() {
    super.initState();
    // 预先填充真实数据
    final vendor = widget.bundle.vendor;
    _storeNameController = TextEditingController(text: vendor.storeName);
    _addressController = TextEditingController(text: vendor.storeAddress);
    _vendorType = vendor.vendorType;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- 保存店铺详情 ---
  Future<void> _saveStoreDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // 使用 'copyWith' 创建更新后的 VendorModel
        final updatedVendor = widget.bundle.vendor.copyWith(
          storeName: _storeNameController.text.trim(),
          storeAddress: _addressController.text.trim(),
          vendorType: _vendorType,
        );

        // 调用 Repository 更新
        await _repo.updateVendor(updatedVendor);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store details updated successfully!'),
              backgroundColor: kSecondaryAccentColor,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update: $e'),
                backgroundColor: kPrimaryActionColor),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- (辅助) 全新设计的可重用文本输入框 ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon, // <-- (新增) 图标
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, // 浮动标签
          prefixIcon: Icon(icon, color: kTextColor.withAlpha(153)), // 前缀图标
          fillColor: kAppBackgroundColor, // 匹配背景
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
            borderSide: const BorderSide(color: kPrimaryActionColor, width: 2),
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
              // --- (新增) 卡片 1: 店铺详情 ---
              Card(
                elevation: 2,
                shadowColor: kTextColor.withOpacity(0.1),
                color: kCardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor.withAlpha(204),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- (已修改) 带图标的文本框 ---
                      _buildTextField(
                        label: 'Store Name',
                        controller: _storeNameController,
                        icon: Icons.store_mall_directory_outlined,
                      ),
                      _buildTextField(
                        label: 'Store Address',
                        controller: _addressController,
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- (新增) 卡片 2: 供应商类型 ---
              Card(
                elevation: 2,
                shadowColor: kTextColor.withOpacity(0.1),
                color: kCardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor.withAlpha(204),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- Vendor Type 选择器 ---
                      SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                              value: 'Blindbox', // 匹配你的注册页面
                              label: Text('Blindbox'),
                              icon: Icon(Icons.card_giftcard)),
                          ButtonSegment<String>(
                              value: 'Grocery', // 匹配你的注册页面
                              label: Text('Grocery'),
                              icon: Icon(Icons.shopping_cart)),
                        ],
                        selected: <String>{_vendorType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _vendorType = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: kAppBackgroundColor,
                          foregroundColor: kTextColor.withOpacity(0.7),
                          selectedForegroundColor: kPrimaryActionColor,
                          selectedBackgroundColor:
                              kPrimaryActionColor.withOpacity(0.1),
                          side: BorderSide(color: kTextColor.withAlpha(51)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 保存按钮 ---
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
                  onPressed: _isLoading ? null : _saveStoreDetails,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kTextColor),
                        )
                      : const Text('Save Changes',
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
