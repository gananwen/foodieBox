import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'screens/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/styles.dart';

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
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
