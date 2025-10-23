import 'package:flutter/material.dart';
import '../../../util/styles.dart';
import '../../../widgets/base_page.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 3, // index for Browse
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            'Browse Page',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSecondaryAccentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Here you can browse available items, shops, or promotions!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
