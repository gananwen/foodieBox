import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../util/styles.dart';
// 1. 导入你分开的登录页面
import '../auth/vendor_login.dart';
import '../auth/user_login.dart'; // 我们下一步会创建这个

class OnboardingRoleSelectionPage extends StatefulWidget {
  const OnboardingRoleSelectionPage({super.key});

  @override
  State<OnboardingRoleSelectionPage> createState() =>
      _OnboardingRoleSelectionPageState();
}

enum UserRole { user, vendor }

class _OnboardingRoleSelectionPageState
    extends State<OnboardingRoleSelectionPage> with TickerProviderStateMixin {
  UserRole? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  UserRole? _lastSelectedRoleForAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });

    if (_lastSelectedRoleForAnimation != role) {
      _animationController.forward(from: 0.0);
      _lastSelectedRoleForAnimation = role;
    }
  }

  // --- 2. (已修改) 更新导航逻辑 ---
  Future<void> _setCompleteAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // 根据选择的角色决定跳转到哪个页面
    Widget destinationPage;
    if (_selectedRole == UserRole.vendor) {
      destinationPage = const VendorLoginPage();
    } else {
      destinationPage = const LoginPage(); // 默认跳转到顾客登录
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => destinationPage, // <-- 跳转到正确的页面
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- 3. (已修改) 更新 _navigateToLogin ---
  void _navigateToLogin() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue.')),
      );
      return;
    }
    // 现在这个函数会根据 _selectedRole 跳转
    _setCompleteAndNavigate();
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required String imageAsset,
    required Color accentColor,
  }) {
    final isSelected = _selectedRole == role;

    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade200,
          width: isSelected ? 4 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? accentColor.withOpacity(0.4) : Colors.black12,
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
              color: isSelected ? accentColor : kCardColor,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: kCardColor)
                : null,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: cardContent,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color userAccentColor = kYellowMedium;
    const Color vendorAccentColor =
        kPrimaryActionColor; // <-- 4. (修复) 我把这个改成了 Pink

    return Container(
      color: kOnboardingBackgroundColor,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Choose Your Role',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Are you here to buy sustainable groceries or sell your surplus food?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          _buildRoleCard(
            role: UserRole.user,
            title: 'I am a Customer',
            description:
                'Find amazing discounted food, blindboxes, and near-expiry items.',
            accentColor: userAccentColor,
            imageAsset: 'assets/images/role_user.png',
          ),
          _buildRoleCard(
            role: UserRole.vendor,
            title: 'I am a Vendor/Seller',
            description:
                'List your surplus or near-expiry products to reduce food waste.',
            accentColor: vendorAccentColor, // <-- 5. (修复) 使用 Pink
            imageAsset: 'assets/images/role_vendor.png',
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              // 6. (修复) 按钮颜色会根据选择而改变
              backgroundColor: _selectedRole == null
                  ? Colors.grey.shade300
                  : (_selectedRole == UserRole.vendor
                      ? vendorAccentColor // 供应商按钮是 Pink
                      : userAccentColor), // 顾客按钮是 Yellow
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Text('Continue', // <-- 7. (修复) 按钮文字
                style: TextStyle(
                    color: _selectedRole == UserRole.vendor
                        ? kCardColor // Pink 按钮配白字
                        : kTextColor, // Yellow 按钮配黑字
                    fontSize: 18)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
