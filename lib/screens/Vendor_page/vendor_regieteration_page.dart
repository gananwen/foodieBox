import 'dart:io'; // 用于 File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 用于图片上传
import 'package:image_picker/image_picker.dart'; // 用于图片选择
import 'package:flutter/foundation.dart'; // 用于 debugPrint
import '../../util/styles.dart';
import '../../models/user.dart'; // 导入 UserModel
import '../../models/vendor.dart'; // 导入 VendorModel
import 'vendor_home_page.dart';

// --- (新增) 导入你的 MapPage ---
// (请确保这个相对路径是正确的)
import '../users/map_page.dart';

class VendorRegistrationPage extends StatefulWidget {
  const VendorRegistrationPage({super.key});

  @override
  State<VendorRegistrationPage> createState() => _VendorRegistrationPageState();
}

class _VendorRegistrationPageState extends State<VendorRegistrationPage> {
  // Stepper (步骤) 控制
  int _currentStep = 0;

  // Global Keys 用于表单验证
  final _step1Key = GlobalKey<FormState>(); // 账户
  final _step2Key = GlobalKey<FormState>(); // 店铺详情
  final _step3Key = GlobalKey<FormState>(); // 文件

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController =
      TextEditingController(); // <-- 地址 controller 已存在
  final _storePhoneController = TextEditingController();

  // --- (新增) 供应商类型状态 ---
  String? _selectedVendorType; // 'Blindbox' 或 'Grocery'

  // Image Files
  File? _businessPhoto;
  File? _businessLicense;
  File? _halalCertificate;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    // 释放所有 controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  // --- (FIX: 重新添加丢失的辅助函数) ---

  // --- (辅助) 图片选择函数 ---
  Future<File?> _pickImage() async {
    // (使用 .gallery，根据你之前的请求)
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // --- (辅助) 上传图片并获取 URL ---
  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      rethrow; // 重新抛出错误，让 _submitRegistration 知道
    }
  }

  // --- (核心) 注册函数 ---
  Future<void> _submitRegistration() async {
    // 确保所有表单都验证通过
    bool step1Valid = _step1Key.currentState?.validate() ?? false;
    bool step2Valid = _step2Key.currentState?.validate() ?? false;

    // 检查 vendorType 和图片
    if (!step1Valid ||
        !step2Valid ||
        _selectedVendorType == null ||
        _businessLicense == null ||
        _businessPhoto == null) {
      // 如果验证失败或缺少字段，自动跳回相应步骤
      setState(() {
        if (!step1Valid) {
          _currentStep = 0;
        } else if (!step2Valid || _selectedVendorType == null) {
          _currentStep = 1;
        } else {
          _currentStep = 2; // 缺少图片
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please fill all required fields and upload required images.'),
              backgroundColor: kPrimaryActionColor),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 在 Firebase Auth 中创建用户
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }
      String uid = user.uid;

      // 2. 上传所有图片到 Firebase Storage
      String businessPhotoUrl =
          await _uploadFile(_businessPhoto!, 'vendors/$uid/business_photo.jpg');
      String businessLicenseUrl = await _uploadFile(
          _businessLicense!, 'vendors/$uid/business_license.jpg');
      String halalCertificateUrl = _halalCertificate != null
          ? await _uploadFile(_halalCertificate!, 'vendors/$uid/halal_cert.jpg')
          : '';

      // 3. 创建 UserModel (用于 'users' 集合)
      final nameParts = _fullNameController.text.trim().split(' ');
      final userModel = UserModel(
        uid: uid,
        email: _emailController.text.trim(),
        firstName: nameParts.first,
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        username: _emailController.text.trim().split('@').first,
        role: 'Vendor',
      );

      // 4. 创建 VendorModel (用于 'vendors' 集合)
      final vendorModel = VendorModel(
        uid: uid,
        storeName: _storeNameController.text.trim(),
        storeAddress: _storeAddressController.text.trim(),
        storePhone: _storePhoneController.text.trim(),
        vendorType: _selectedVendorType!,
        businessPhotoUrl: businessPhotoUrl,
        businessLicenseUrl: businessLicenseUrl,
        halalCertificateUrl: halalCertificateUrl,
      );

      // 5. 使用 "Batch Write" (批量写入)
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);
      batch.set(userDoc, userModel.toMap());
      DocumentReference vendorDoc =
          FirebaseFirestore.instance.collection('vendors').doc(uid);
      batch.set(vendorDoc, vendorModel.toMap());
      await batch.commit();

      // 6. 注册成功
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorHomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: kPrimaryActionColor),
        );
      }
    }
  }

  // --- (新增) 导航到地图并获取地址的函数 ---
  Future<void> _navigateToMapPage() async {
    try {
      // 1. 导航到 MapPage 并等待结果
      // MapPage 会返回一个 Map<String, dynamic>
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );

      // 2. 检查结果并更新 controller
      if (result != null && result is Map<String, dynamic>) {
        final String address = result['address'] ?? 'No address selected';
        // final double lat = result['lat']; // 你也可以保存纬度
        // final double lng = result['lng']; // 你也可以保存经度

        setState(() {
          _storeAddressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error navigating to map: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Vendor Registration'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor))
          : Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                bool isLastStep = _currentStep == 2;
                bool isCurrentStepValid = true;
                if (_currentStep == 0) {
                  isCurrentStepValid = _step1Key.currentState!.validate();
                } else if (_currentStep == 1) {
                  isCurrentStepValid = _step2Key.currentState!.validate();
                  // --- (新增) 额外检查类型 ---
                  if (_selectedVendorType == null) {
                    isCurrentStepValid = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a vendor type'),
                          backgroundColor: kPrimaryActionColor),
                    );
                  }
                }

                if (isCurrentStepValid) {
                  if (isLastStep) {
                    _submitRegistration();
                  } else {
                    setState(() => _currentStep += 1);
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              steps: [
                _buildAccountStep(),
                _buildStoreDetailsStep(), // <-- (修改)
                _buildDocumentsStep(),
              ],
            ),
    );
  }

  // --- (辅助) 步骤 1: 账户表单 ---
  Step _buildAccountStep() {
    return Step(
      title: const Text('Account'),
      isActive: _currentStep >= 0,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            _buildTextField(_fullNameController, 'Full Name', Icons.person),
            _buildTextField(
              _emailController,
              'Email',
              Icons.email,
              inputType: TextInputType.emailAddress,
            ),
            _buildTextField(
              _passwordController,
              'Password',
              Icons.lock,
              obscureText: true,
            ),
            _buildTextField(
              _confirmPassController,
              'Confirm Password',
              Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- (辅助) 步骤 2: 店铺详情表单 (已修改) ---
  Step _buildStoreDetailsStep() {
    return Step(
      title: const Text('Store Details'),
      isActive: _currentStep >= 1,
      content: Form(
        key: _step2Key,
        child: Column(
          children: [
            _buildTextField(_storeNameController, 'Store Name', Icons.store),

            // --- (修改) ---
            // 将 _buildTextField 替换为 _buildAddressPicker
            _buildAddressPicker(
              _storeAddressController,
              'Store Address',
              Icons.location_on,
              _navigateToMapPage, // 传递导航函数
            ),
            // --- (结束修改) ---

            _buildTextField(
              _storePhoneController,
              'Store Phone (e.g., 012...)',
              Icons.phone,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // --- (新增) Vendor Type 选择器 ---
            _buildVendorTypeSelector(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- (辅助) 步骤 3: 文件上传表单 ---
  Step _buildDocumentsStep() {
    return Step(
      title: const Text('Documents'),
      isActive: _currentStep >= 2,
      content: Form(
        key: _step3Key,
        child: Column(
          children: [
            _buildImagePicker(
              'Business Photo (Required)',
              _businessPhoto,
              () async {
                final file = await _pickImage();
                if (file != null) setState(() => _businessPhoto = file);
              },
            ),
            _buildImagePicker(
              'Business License (Required)',
              _businessLicense,
              () async {
                final file = await _pickImage();
                if (file != null) setState(() => _businessLicense = file);
              },
            ),
            _buildImagePicker(
              'Halal Certificate (Optional)',
              _halalCertificate,
              () async {
                final file = await _pickImage();
                if (file != null) setState(() => _halalCertificate = file);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- (辅助) 可重用的文本输入框 ---
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? inputType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kTextColor.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: kCardColor,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            },
      ),
    );
  }

  // --- (新增) 用于地址选择的 Widget ---
  // (这个 widget 模仿了 _buildTextField，但是是只读的，并且有 onTap)
  Widget _buildAddressPicker(
    TextEditingController controller,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        // 1. 用 GestureDetector 包裹
        onTap: onTap, // 2. 触发 onTap
        child: AbsorbPointer(
          // 3. 阻止 TextFormFielld 的内部点击
          child: TextFormField(
            controller: controller,
            readOnly: true, // 4. 设为只读
            decoration: InputDecoration(
              labelText: label,
              hintText: 'Tap to choose location', // 提示
              prefixIcon: Icon(icon, color: kTextColor.withOpacity(0.7)),
              // (可选) 添加一个地图图标
              suffixIcon:
                  const Icon(Icons.map_outlined, color: kPrimaryActionColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: kCardColor,
            ),
            // 验证器仍然会检查 _storeAddressController 是否为空
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  // --- (辅助) 可重用的图片选择器 ---
  Widget _buildImagePicker(String label, File? file, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: kCardColor,
        ),
        child: ListTile(
          leading: Icon(file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? kCategoryColor : Colors.grey),
          title: Text(file != null ? file.path.split('/').last : label,
              style: TextStyle(
                  fontSize: 14,
                  color: file != null ? kTextColor : Colors.grey.shade700)),
          onTap: onPressed,
        ),
      ),
    );
  }

  // --- (新增) Vendor Type 选择器 Widget ---
  Widget _buildVendorTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            'Vendor Type (Required)',
            style: TextStyle(fontSize: 14, color: kTextColor),
          ),
        ),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'Blindbox',
              label: Text('Blindbox'),
              icon: Icon(Icons.card_giftcard_outlined),
            ),
            ButtonSegment<String>(
              value: 'Grocery',
              label: Text('Grocery'),
              icon: Icon(Icons.shopping_cart_outlined),
            ),
          ],
          selected: _selectedVendorType != null
              ? <String>{_selectedVendorType!}
              : <String>{},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedVendorType = newSelection.first;
            });
          },

          // --- (FIX) 添加这一行 ---
          emptySelectionAllowed: true,
          // --- (FIX) ---

          style: SegmentedButton.styleFrom(
            backgroundColor: kCardColor,
            foregroundColor: kTextColor.withOpacity(0.7),
            selectedForegroundColor: kPrimaryActionColor,
            selectedBackgroundColor: kPrimaryActionColor.withOpacity(0.1),
            side: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}
