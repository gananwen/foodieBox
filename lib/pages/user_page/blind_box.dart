import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import 'base_page.dart';

class BlindBox extends StatelessWidget {
  const BlindBox({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'BlindBox',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Surprise yourself with curated food bundles and exclusive deals!',
              style: TextStyle(fontSize: 16, color: kTextColor),
            ),
          ),
          SizedBox(height: 40),
          Center(
            child: Text(
              'Coming soon...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
