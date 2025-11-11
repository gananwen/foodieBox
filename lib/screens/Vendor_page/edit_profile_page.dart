import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'package:flutter/foundation.dart'; // 用于 debugPrint

// --- (完整) 编辑个人资料页面 ---
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // --- 虚拟数据 (模拟从 Firebase 加载) ---
  final String _currentName = "Afsar Hossen";
  final String _currentEmail = "vendor@store.com";

  @override
  void initState() {
    super.initState();
    // 预先填充当前数据
    _nameController = TextEditingController(text: _currentName);
    _emailController = TextEditingController(text: _currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- 保存个人资料 ---
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // TODO: 在这里处理 Firebase 更新逻辑
      // 1. 重新认证 (如果需要更改密码或邮箱)
      // 2. 更新 Firestore 'users' 集合中的 'name'
      // 3. 更新 Firebase Auth 的 'email'
      // 4. 更新 Firebase Auth 的 'password'

      debugPrint('Name: ${_nameController.text}');
      debugPrint('Email: ${_emailController.text}');

      if (_newPassController.text.isNotEmpty) {
        debugPrint('Password Change Requested');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
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
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
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
          obscureText: obscureText,
          decoration: InputDecoration(
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
          keyboardType: inputType,
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- (辅助) 分区标题 ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: kTextColor.withAlpha(179), // 70%
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
              // --- 个人资料部分 ---
              _buildSectionHeader('PERSONAL'),
              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              // --- 更改密码部分 ---
              _buildSectionHeader('CHANGE PASSWORD'),
              _buildTextField(
                label: 'Current Password',
                controller: _currentPassController,
                obscureText: true,
                // 密码可以为空 (如果不想更改)
              ),
              _buildTextField(
                label: 'New Password',
                controller: _newPassController,
                obscureText: true,
                validator: (value) {
                  // 仅当新密码不为空时，才验证"当前密码"
                  if (value != null && value.isNotEmpty) {
                    if (_currentPassController.text.isEmpty) {
                      return 'Please enter your current password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Confirm New Password',
                controller: _confirmPassController,
                obscureText: true,
                validator: (value) {
                  if (_newPassController.text.isNotEmpty &&
                      value != _newPassController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
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
                  onPressed: _saveProfile,
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
