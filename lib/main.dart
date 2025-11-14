import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_decision_wrapper.dart';
import 'screens/admin/admin_home_page.dart';
import 'screens/auth_wrapper.dart';
import 'screens/auth/user_login.dart';
import 'screens/users/main_page.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/users/order_confirmation_page.dart';
import 'screens/auth/vendor_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/Vendor_page/vendor_home_page.dart';
import 'screens/users/order_failure_page.dart';
import 'firebase_options.dart';
import 'util/styles.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- MODIFIED: Wrap your app in the CartProvider ---
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(), // Creates the cart state
      child: const MyApp(), // Your app is now a child of the provider
    ),
  );
  // --- END MODIFICATION ---
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
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}