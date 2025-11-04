import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../util/styles.dart';
import '../auth_wrapper.dart'; // Ensure this path is correct

class OnboardingRoleSelectionPage extends StatefulWidget {
  const OnboardingRoleSelectionPage({super.key});

  @override
  State<OnboardingRoleSelectionPage> createState() => _OnboardingRoleSelectionPageState();
}

enum UserRole { user, vendor }

class _OnboardingRoleSelectionPageState extends State<OnboardingRoleSelectionPage> with SingleTickerProviderStateMixin {
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

  Future<void> _setCompleteAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(), 
      ),
      (Route<dynamic> route) => false, 
    );
  }

  void _navigateToLogin() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue.')),
      );
      return;
    }
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
          // Use the accentColor (kYellowMedium or kPrimaryActionColor) for the border
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
          // Left Side: Image
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

          // Center: Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
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

          // Right Side: Selection Indicator
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
    // User Role: Uses kYellowMedium (darker yellow/amber)
    const Color userAccentColor = kYellowMedium; 
    
    // Vendor Role: Uses the team's kPrimaryActionColor (e.g., Maroon/Deep Teal)
    const Color vendorAccentColor = kPrimaryActionColor; 

    return Container(
      color: kOnboardingBackgroundColor, 
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Text(
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

          // --- User Card (Uses kYellowMedium) ---
          _buildRoleCard(
            role: UserRole.user,
            title: 'I am a Customer',
            description: 'Find amazing discounted food, blindboxes, and near-expiry items.',
            accentColor: userAccentColor,
            imageAsset: 'assets/images/role_user.png', 
          ),

          // --- Vendor Card (Uses kPrimaryActionColor) ---
          _buildRoleCard(
            role: UserRole.vendor,
            title: 'I am a Vendor/Seller',
            description: 'List your surplus or near-expiry products to reduce food waste.',
            accentColor:  userAccentColor,
            imageAsset: 'assets/images/role_vendor.png', 
          ),
          
          const Spacer(),


          ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedRole != null ?   kYellowMedium :  Colors.grey.shade300, 
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('Continue to Login', style: TextStyle(color: kCardColor, fontSize: 18)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}