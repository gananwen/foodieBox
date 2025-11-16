// 路径: lib/pages/vendor_page/vendor_login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ( ✨ 1. ADD THIS )
import '../../util/styles.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../screens/Vendor_page/vendor_home_page.dart';
import '../../screens/Vendor_page/vendor_regieteration_page.dart';
import '../../models/vendor.dart'; // <-- ( ✨ 2. ADD THIS )
import '../../screens/Vendor_page/pending_approval_page.dart';

class VendorLoginPage extends StatefulWidget {
  const VendorLoginPage({super.key});

  @override
  State<VendorLoginPage> createState() => _VendorLoginPageState();
}

class _VendorLoginPageState extends State<VendorLoginPage>
    with SingleTickerProviderStateMixin {
  static const String _logoPath = 'assets/images/FoodieBoxLogo.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  // --- ( ✨ 4. ADD FIRESTORE INSTANCE ✨ ) ---
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ( ✨ 5. THIS FUNCTION IS NOW UPDATED ✨ ) ---
  Future<void> _signInVendor() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter email and password")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign in with Auth
      final user = await _authRepo.signInWithEmail(email, password);
      if (user == null) {
        throw Exception("Login failed. Please try again.");
      }

      // Step 2: Check the 'users' collection for 'Vendor' role
      final userData = await _userRepo.getUserData(user.uid);
      if (userData?.role != 'Vendor') {
        await _authRepo.signOut(); // Log out non-vendors
        throw Exception("Access denied: This account is not a vendor.");
      }

      // Step 3: Check the 'vendors' collection for 'isApproved' status
      final vendorDoc = await _db.collection('vendors').doc(user.uid).get();
      if (!vendorDoc.exists) {
        await _authRepo.signOut(); // Log out if vendor data is missing
        throw Exception("Vendor data not found. Please contact support.");
      }

      final vendorData = VendorModel.fromMap(vendorDoc.data()!);

      // Step 4: Navigate based on approval status
      if (mounted) {
        if (vendorData.isApproved) {
          // --- APPROVED: Go to Home Page ---
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vendor login successful")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VendorHomePage()),
          );
        } else {
          // --- NOT APPROVED: Go to Pending Page ---
          await _authRepo.signOut(); // Log them out
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _animation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Image.asset(_logoPath, height: 200),
                ),
              ),
              const Center(
                child: Text(
                  'Vendor Login',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _CustomInputField(label: 'Email', controller: _emailController),
              const SizedBox(height: 20),
              _CustomInputField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signInVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCategoryColor, // 绿色
                        foregroundColor: kTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have a vendor account? ",
                    style: TextStyle(color: kTextColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorRegistrationPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register here',
                      style: TextStyle(
                        color: kPrimaryActionColor, // Pink
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
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

// (This helper class is unchanged)
class _CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  const _CustomInputField({
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kTextColor)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Input',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => controller.clear(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide:
                  const BorderSide(color: kPrimaryActionColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
