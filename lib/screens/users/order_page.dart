import 'package:flutter/material.dart';
import '../../../utils/styles.dart';
import '../../../widgets/base_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 4, // index for Orders
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            'Orders Page',
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
              'Here you can view your past and current orders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
