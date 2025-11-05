import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_decision_wrapper.dart'; 
import 'screens/admin/admin_home_page.dart'; 
import 'screens/auth_wrapper.dart'; 
import 'screens/auth/user_login.dart'; 
import 'screens/users/main_page.dart'; 
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/users/checkout_page.dart';
import 'screens/auth/vendor_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'util/styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodieBox',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryActionColor,
          background: kAppBackgroundColor,
          primary: kPrimaryActionColor,
        ),
        scaffoldBackgroundColor: kAppBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: kTextColor),
          titleTextStyle: TextStyle(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const VendorLoginPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}