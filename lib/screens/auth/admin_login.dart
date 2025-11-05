import 'package:flutter/material.dart';
import '../../util/styles.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  static const String _logoPath = 'assets/images/FoodieBoxLogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? screenWidth * 0.25 : 30.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 60),

                // --- Animated Logo ---
                ScaleTransition(
                  scale: _animation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Image.asset(
                      _logoPath,
                      height: isWideScreen ? 220 : 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // --- Admin Login Title ---
                const Text(
                  'Welcome Back, Admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 40),

                // --- Input Fields ---
                const _CustomInputField(label: 'Email'),
                const SizedBox(height: 20),
                const _CustomInputField(label: 'Password', obscureText: true),
                const SizedBox(height: 30),

                // --- Sign In Button ---
                ElevatedButton(
                  onPressed: () {
                    // Temporary placeholder — no navigation yet
                  },
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomInputField extends StatelessWidget {
  final String label;
  final bool obscureText;

  const _CustomInputField({required this.label, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

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
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            fillColor: kCardColor,
            filled: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {},
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
              borderSide: const BorderSide(
                color: kPrimaryActionColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isWideScreen ? 18 : 12,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AdminLoginPage(),
  ));
}
