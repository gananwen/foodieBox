import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 导入你需要跳转的所有页面
// --- (修复) 导入你新的 user_login.dart 路径 ---
import '../../util/styles.Dart';
import '../screens/auth/user_login.dart';
import '../screens/Vendor_page/vendor_home_page.dart'; // 你的 vendor 首页
import '../screens/users/main_page.dart'; // 你队友的 customer 首页
// import 'admin_dashboard_page.dart'; // 你们以后会创建的 admin 页面

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          // --- (修复) 返回 Customer 的登录页 ---
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
                backgroundColor: kAppBackgroundColor, // 使用你的样式
                body: Center(
                  child: CircularProgressIndicator(color: kPrimaryActionColor),
                ),
              );
            }

            if (firestoreSnapshot.hasError ||
                !firestoreSnapshot.hasData ||
                !firestoreSnapshot.data!.exists) {
              // --- (修复) 返回 Customer 的登录页 ---
              return const LoginPage();
            }

            final data = firestoreSnapshot.data!.data() as Map<String, dynamic>;
            final String role = data['role'] ?? 'Customer';

            switch (role) {
              case 'Admin':
                return const VendorHomePage(); // 暂时

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
