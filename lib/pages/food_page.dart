import 'package:flutter/material.dart';

// Import styles to use the correct background color
import '../utils/styles.dart'; 

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Food Page (To Be Built)'),
        backgroundColor: kPrimaryActionColor,
      ),
      body: const Center(
        child: Text('Food ordering UI will go here.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}