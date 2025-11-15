import 'package:flutter/material.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:qr_flutter/qr_flutter.dart'; // You might need to add this package

class PickupConfirmationPage extends StatelessWidget {
  final String orderId;
  final String pickupId;
  final String vendorName;
  final String vendorAddress;
  final double total;

  const PickupConfirmationPage({
    super.key,
    required this.orderId,
    required this.pickupId,
    required this.vendorName,
    required this.vendorAddress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        title: const Text('Order Confirmed', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: kPrimaryActionColor, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order is being prepared.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),

              // --- Pickup ID Card ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kYellowLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryActionColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'Show this ID at the counter',
                      style: kLabelTextStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickupId,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // You can also show a QR code of the pickupId
                    QrImageView(
                      data: 'pickup_order_id:$pickupId',
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Store Details ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vendorAddress,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RM${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to the app's home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryActionColor,
            foregroundColor: kTextColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              const Text('Back to Home', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}