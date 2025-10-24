import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:foodiebox/screens/Vendor_page/vendor_home_page.dart';
import '../screens/users/main_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        final User user = authSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (firestoreSnapshot.hasError ||
                !firestoreSnapshot.hasData ||
                !firestoreSnapshot.data!.exists) {
              return const LoginPage();
            }

            final data = firestoreSnapshot.data!.data() as Map<String, dynamic>;

            final String role = data['role'] ?? 'Customer';

            switch (role) {
              case 'Admin':
                return const VendorHomePage();

              case 'Vendor':
                return const VendorHomePage();

              case 'Customer':
              default:
                return const MainPage();
            }
          },
        );
      },
    );
  }
}
