import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/styles.dart';
import 'main_page.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const String _logoPath = 'assets/images/FoodieBoxLogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if ([firstName, lastName, username, email, password, confirmPassword]
        .any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Password must be at least 6 characters")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepo.signUp(email: email, password: password);
      if (user == null) throw Exception("Failed to create user");

      await _userRepo.createUserData(UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
      ));

      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Sign up successful! Please verify your email.")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Sign up failed";
      if (e.code == 'weak-password') message = "Password is too weak";
      if (e.code == 'email-already-in-use') message = "Email already in use";
      if (e.code == 'invalid-email') message = "Invalid email";

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
            children: [
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _animation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child:
                      Image.asset(_logoPath, height: 200, fit: BoxFit.contain),
                ),
              ),
              const Text("Let's Get Started",
                  textAlign: TextAlign.center, style: kLabelTextStyle),
              const SizedBox(height: 8),
              const Text(
                "Create an account to start purchasing your favorite food or groceries!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kTextColor),
              ),
              const SizedBox(height: 30),
              _CustomInputField(
                  label: 'First Name', controller: _firstNameController),
              const SizedBox(height: 20),
              _CustomInputField(
                  label: 'Last Name', controller: _lastNameController),
              const SizedBox(height: 20),
              _CustomInputField(
                  label: 'Username', controller: _usernameController),
              const SizedBox(height: 20),
              _CustomInputField(label: 'Email', controller: _emailController),
              const SizedBox(height: 20),
              _CustomInputField(
                  label: 'Password',
                  obscureText: true,
                  controller: _passwordController),
              const SizedBox(height: 20),
              _CustomInputField(
                  label: 'Confirm Password',
                  obscureText: true,
                  controller: _confirmPasswordController),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCategoryColor,
                        foregroundColor: kTextColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ",
                      style: TextStyle(color: kTextColor)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Login here', style: kLinkTextStyle),
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

  const _CustomInputField(
      {required this.label,
      required this.controller,
      this.obscureText = false});

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
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Input',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => controller.clear()),
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
