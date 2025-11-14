import 'package:flutter/material.dart';
// --- MODIFIED IMPORT ---
// We will import the CartPage instead of the CheckoutPage
import 'package:foodiebox/screens/users/cart_page.dart';
import 'package:foodiebox/screens/users/main_page.dart'; // To go back home
// --- END MODIFIED IMPORT ---

class OrderFailurePage extends StatelessWidget {
  const OrderFailurePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Failed', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 10),
            const Text(
              'Oops! Order Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Something went terribly wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // --- MODIFIED NAVIGATION ---
                      // Go back to the Cart Page to try again
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartPage()),
                      );
                      // --- END MODIFIED NAVIGATION ---
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
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
                      foregroundColor: Colors.black,
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