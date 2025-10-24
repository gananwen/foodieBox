import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../util/styles.dart';
import '../users/main_page.dart';
import 'user_register.dart';
import '../../screens/auth/user_forgot_password.dart';
import '../../repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const String _logoPath = 'assets/images/FoodieBoxLogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthRepository _authRepo = AuthRepository();
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

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepo.signInWithEmail(email, password);

      if (user == null) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: "No user found");
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Login successful")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.signInWithGoogle();
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In successful")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In canceled")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
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
                  child: Image.asset(
                    _logoPath,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _CustomInputField(label: 'Email', controller: _emailController),
              const SizedBox(height: 20),
              _CustomInputField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserForgotPasswordPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: kTextColor, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCategoryColor,
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
              const Divider(color: kTextColor),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: const _SocialIcon(
                      icon: Icons.g_mobiledata_outlined,
                      label: 'G',
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 40),
                  const _SocialIcon(icon: Icons.facebook, label: 'f', size: 24),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Don't have an account? ",
                      style: TextStyle(color: kTextColor)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
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
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: kTextColor),
          ),
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
              onPressed: () {
                controller.clear();
              },
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

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;

  const _SocialIcon({
    required this.icon,
    required this.label,
    required this.size,
  });

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
            ? Text(
                label,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              )
            : Icon(icon, size: size, color: kTextColor),
      ),
    );
  }
}
