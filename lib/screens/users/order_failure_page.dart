import 'package:flutter/material.dart';
import 'package:foodiebox/screens/users/cart_page.dart';
import 'package:foodiebox/screens/users/main_page.dart';
import 'package:foodiebox/util/styles.dart';

class OrderFailurePage extends StatelessWidget {
  final String? rejectionReason;

  const OrderFailurePage({super.key, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    // Determine the title and subtitle based on whether a reason is provided
    final String title = rejectionReason != null 
        ? 'Payment Rejected' 
        : 'Oops! Order Failed';
    
    final String subtitle = rejectionReason ?? 'Something went terribly wrong.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 10),
            Text(
              title,
              style: kLabelTextStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: kHintTextStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Go back to the Cart Page to try again
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kYellowMedium,
                      foregroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Please Try Again'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to the main page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}