// 路径: lib/pages/vendor_page/pending_approval_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../util/styles.dart';
import '../../screens/auth/vendor_login.dart'; // To log out and go back to login

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  // Helper function to log the user out
  Future<void> _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const VendorLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kAppBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: kPrimaryActionColor, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Pending Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your vendor account has been registered but is awaiting approval from an admin. Please check back later.',
                style: TextStyle(
                  fontSize: 16,
                  color: kTextColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _logOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryAccentColor,
                  foregroundColor: kTextColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
