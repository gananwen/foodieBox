import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notifier to handle app theme
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> updateThemePreference(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('darkMode', isDark);
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
}
