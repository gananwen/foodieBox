import 'package:flutter/material.dart';
import '../utils/styles.dart';
import '../pages/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Using the path specified for your logo image
  static const String _logoPath = 'assets/images/FoodieBoxLogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Setup for the pulsing logo animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor, // FEFFE1 background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 60),

              // --- 1. Logo Area with Pulsing Animation ---
              ScaleTransition(
                scale: _animation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Image.asset(
                    _logoPath,
                    height: 200, // Final size
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 2. Customer/Vendor Toggle
              Row(
                children: <Widget>[
                  Expanded(
                      child: _RoleButton(
                          label: 'Customer',
                          isSelected: true,
                          onPressed: () {})),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _RoleButton(
                          label: 'Vendor',
                          isSelected: false,
                          onPressed: () {})),
                ],
              ),
              const SizedBox(height: 30),

              // 3. Input Fields
              const _CustomInputField(label: 'Email'),
              const SizedBox(height: 20),
              const _CustomInputField(label: 'Password', obscureText: true),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Forgot password?',
                      style: TextStyle(color: kTextColor, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Sign In Button (Light Green E8FFC9)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCategoryColor,
                  foregroundColor: kTextColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              // 5. Separator
              const Divider(color: kTextColor),
              const SizedBox(height: 20),

              // 6. Social Login Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SocialIcon(
                      icon: Icons.g_mobiledata_outlined, label: 'G', size: 30),
                  const SizedBox(width: 40),
                  const _SocialIcon(icon: Icons.facebook, label: 'f', size: 24),
                ],
              ),
              const SizedBox(height: 20),

              // 7. Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Don't have an account? ",
                      style: TextStyle(color: kTextColor)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                    child: const Text('Sign Up', style: kLinkTextStyle),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _RoleButton(
      {required this.label, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: kCardColor,
        foregroundColor: kTextColor,
        side: const BorderSide(color: Colors.grey, width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _CustomInputField extends StatelessWidget {
  final String label;
  final bool obscureText;

  const _CustomInputField({required this.label, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: kTextColor))),
        const SizedBox(height: 4),
        TextField(
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Input',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18), onPressed: () {}),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: kPrimaryActionColor, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;

  const _SocialIcon(
      {required this.icon, required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kTextColor, width: 1.5),
      ),
      child: Center(
        child: label == 'G'
            ? Text(label,
                style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.bold,
                    color: kTextColor))
            : Icon(icon, size: size, color: kTextColor),
      ),
    );
  }
}
