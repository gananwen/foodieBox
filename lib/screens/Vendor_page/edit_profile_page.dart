import 'package:flutter/material.dart';
import '../../util/styles.dart';
// --- 1. 导入 Repository 和 Models ---
import '../../repositories/vendor_data_repository.dart';
import 'package:flutter/foundation.dart'; // 用于 debugPrint

class EditProfilePage extends StatefulWidget {
  final VendorDataBundle bundle; // <-- 2. 接收数据
  const EditProfilePage({super.key, required this.bundle});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = VendorDataRepository();
  bool _isLoading = false;

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // --- 3. 预先填充真实数据 ---
    final user = widget.bundle.user;
    _nameController =
        TextEditingController(text: "${user.firstName} ${user.lastName}");
    _emailController = TextEditingController(text: user.email);
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

  // --- 4. (已修改) 保存个人资料 ---
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      // TODO: 密码更改需要单独的 Firebase Auth 逻辑
      // if (_newPassController.text.isNotEmpty) {
      //   debugPrint('Password Change Requested');
      //   // 这里你需要调用 _authRepo.reauthenticate(...)
      //   // 和 _authRepo.updatePassword(...)
      // }

      try {
        final nameParts = _nameController.text.trim().split(' ');
        final firstName = nameParts.first;
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // 5. 使用 'copyWith' 创建更新后的 UserModel
        final updatedUser = widget.bundle.user.copyWith(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          // 'username' 也可以在这里更新
          username: _emailController.text.trim().split('@').first,
        );

        // 6. 调用 Repository 更新
        await _repo.updateUser(updatedUser);

        // TODO: 更新 Auth email (需要重新认证)
        // await _authRepo.updateEmail(...)

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
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
              ),
              _buildTextField(
                label: 'New Password',
                controller: _newPassController,
                obscureText: true,
                validator: (value) {
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

              // --- 7. (已修改) 保存按钮 ---
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
                  // --- 检查 _isLoading ---
                  onPressed: _isLoading ? null : _saveProfile,
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
