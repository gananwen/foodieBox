import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your pages
import 'login_page.dart';
import 'package:foodiebox/pages/Vendor_page/vendor_home_page.dart';
import 'user_page/main_page.dart';
// import 'admin_dashboard_page.dart'; // Create this page for Admins

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for changes in authentication state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // If user is logged out, show LoginPage
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        // If user is logged in, get their User object
        final User user = authSnapshot.data!;

        // Now, check the user's role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, firestoreSnapshot) {
            // Show a loading circle while fetching role
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // If there's an error or no document, log them out
            if (firestoreSnapshot.hasError ||
                !firestoreSnapshot.hasData ||
                !firestoreSnapshot.data!.exists) {
              // You can also sign them out here to be safe
              // FirebaseAuth.instance.signOut();
              return const LoginPage();
            }

            // If data is available, get the role
            // We use .get('role') to access the 'role' field in the document
            final data = firestoreSnapshot.data!.data() as Map<String, dynamic>;
            final String role = data['role'] ??
                'Customer'; // Default to Customer if role is missing

            // --- THIS IS THE REDIRECTION LOGIC ---
            switch (role) {
              case 'Admin':
                // return const AdminDashboardPage(); // TODO: Create this page
                return const VendorHomePage(); // Placeholder
              case 'Vendor':
                return const VendorHomePage();
              case 'Customer':
              default:
                return const MainPage(); // Your Customer homepage
            }
          },
        );
      },
    );
  }
}
