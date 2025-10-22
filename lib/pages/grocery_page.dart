import 'package:flutter/material.dart';

// Import styles to use the correct background color
import '../utils/styles.dart'; 

class GroceryPage extends StatelessWidget {
  const GroceryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Grocery Page (To Be Built)'),
        backgroundColor: kPrimaryActionColor,
      ),
      body: const Center(
        child: Text('Grocery ordering UI will go here.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}