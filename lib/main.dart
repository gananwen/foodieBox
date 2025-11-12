import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/admin/settings/theme_provider.dart';
import 'firebase_options.dart';
import 'screens/users/main_page.dart';
import 'util/styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await loadThemePreference(); // Load saved theme

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'FoodieBox',
          debugShowCheckedModeBanner: false,
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
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: currentMode, // <-- dynamic
          home: const MainPage(),
        );
      },
    );
  }
}
