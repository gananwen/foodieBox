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
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();

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

  // --- (辅助) 图片选择函数 ---
  Future<File?> _pickImage() async {
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
      return '';
    }
  }

  // --- (核心) 注册函数 ---
  Future<void> _submitRegistration() async {
    // 确保所有表单都验证通过
    bool step1Valid = _step1Key.currentState?.validate() ?? false;
    bool step2Valid = _step2Key.currentState?.validate() ?? false;

    if (!step1Valid ||
            !step2Valid ||
            _businessLicense == null || // 营业执照是必需的
            _businessPhoto == null // 店铺照片是必需的
        ) {
      // 如果验证失败或缺少图片，自动跳回第一步
      setState(() {
        if (!step1Valid) {
          _currentStep = 0;
        } else if (!step2Valid) {
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
      // (我们使用 UID 来确保路径唯一)
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
        role: 'Vendor', // *** 关键：设置角色为 Vendor ***
      );

      // 4. 创建 VendorModel (用于 'vendors' 集合)
      final vendorModel = VendorModel(
        uid: uid,
        storeName: _storeNameController.text.trim(),
        storeAddress: _storeAddressController.text.trim(),
        storePhone: _storePhoneController.text.trim(),
        businessPhotoUrl: businessPhotoUrl,
        businessLicenseUrl: businessLicenseUrl,
        halalCertificateUrl: halalCertificateUrl,
        // 其他字段使用默认值
      );

      // 5. 使用 "Batch Write" (批量写入) 来确保两个操作都成功
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 操作 A: 写入 'users' 集合
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);
      batch.set(userDoc, userModel.toMap());

      // 操作 B: 写入 'vendors' 集合
      DocumentReference vendorDoc =
          FirebaseFirestore.instance.collection('vendors').doc(uid);
      batch.set(vendorDoc, vendorModel.toMap());

      // 提交批量操作
      await batch.commit();

      // 6. 注册成功，跳转到 VendorHomePage
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorHomePage()),
          (route) => false, // 移除所有旧页面
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Vendor Registration'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          // 添加返回按钮
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                bool isLastStep = _currentStep == 2;
                // 检查当前步骤的表单是否验证通过
                bool isCurrentStepValid = true;
                if (_currentStep == 0) {
                  isCurrentStepValid = _step1Key.currentState!.validate();
                } else if (_currentStep == 1) {
                  isCurrentStepValid = _step2Key.currentState!.validate();
                }

                if (isCurrentStepValid) {
                  if (isLastStep) {
                    // 如果是最后一步，执行提交
                    _submitRegistration();
                  } else {
                    // 否则，前进到下一步
                    setState(() => _currentStep += 1);
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  // 如果在第一步按 "Cancel"，则返回登录页
                  Navigator.of(context).pop();
                }
              },
              steps: [
                // --- 步骤 1: 账户信息 (Figure 23) ---
                _buildAccountStep(),
                // --- 步骤 2: 店铺详情 (你要求的新增功能) ---
                _buildStoreDetailsStep(),
                // --- 步骤 3: 文件上传 (Figure 24) ---
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

            // --- 2. (已修复) 更新调用方式 ---
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
                // 'validator' 现在是命名参数，可以正常工作
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

  // --- (辅助) 步骤 2: 店铺详情表单 ---
  Step _buildStoreDetailsStep() {
    return Step(
      title: const Text('Store Details'),
      isActive: _currentStep >= 1,
      content: Form(
        key: _step2Key,
        child: Column(
          children: [
            _buildTextField(_storeNameController, 'Store Name', Icons.store),
            _buildTextField(
                _storeAddressController, 'Store Address', Icons.location_on),

            // --- 3. (已修复) 更新调用方式 ---
            _buildTextField(
              _storePhoneController,
              'Store Phone (e.g., 012...)',
              Icons.phone,
              inputType: TextInputType.phone,
            ),
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
            // 你要求的 "Business Photo"
            _buildImagePicker(
              'Business Photo (Required)',
              _businessPhoto,
              () async {
                final file = await _pickImage();
                if (file != null) setState(() => _businessPhoto = file);
              },
            ),
            // "Business License"
            _buildImagePicker(
              'Business License (Required)',
              _businessLicense,
              () async {
                final file = await _pickImage();
                if (file != null) setState(() => _businessLicense = file);
              },
            ),
            // "Halal Certificate"
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
  // --- 1. (已修复) 定义：将可选参数放入 {} 中 ---
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
          prefixIcon: Icon(icon),
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

  // --- (辅助) 可重用的图片选择器 ---
  Widget _buildImagePicker(String label, File? file, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? kSecondaryAccentColor : Colors.grey),
          title: Text(file != null ? 'Image Selected' : label),
          subtitle: file != null ? Text(file.path.split('/').last) : null,
          onTap: onPressed,
        ),
      ),
    );
  }
}
