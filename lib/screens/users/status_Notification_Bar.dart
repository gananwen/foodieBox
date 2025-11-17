import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:foodiebox/screens/users/order_tracking_page.dart';

class OrderStatusChecker extends StatelessWidget {
  final String orderId;
  final Widget child;

  const OrderStatusChecker({
    super.key,
    required this.orderId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Stream order document to get the current status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If order is deleted or not found, just show the child content
          return child;
        }

        final order = OrderModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        final isPending = order.status == 'Awaiting Payment Proof';
        final isVerified = order.status == 'Payment Verified';

        if (!isPending && !isVerified) {
          // Status is complete or rejected, hide the bar
          return child;
        }

        // --- Build the Floating Notification Bar ---
        return Stack(
          children: [
            // 1. The main content of the page (e.g., MainPage content)
            child,

            // 2. The persistent notification bar (aligned to the bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildNotificationBar(context, order, isPending, isVerified),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationBar(
      BuildContext context, OrderModel order, bool isPending, bool isVerified) {
    String message;
    Color color;
    IconData icon;

    if (isPending) {
      message = 'Payment Proof Pending Admin Review';
      color = kPrimaryActionColor; // Yellow/Amber
      icon = Icons.access_time_filled;
    } else if (isVerified) {
      message = 'Order Verified! Awaiting Vendor Acceptance.';
      color = Colors.lightGreen;
      icon = Icons.check_circle_outline;
    } else {
      return const SizedBox.shrink(); // Should not happen
    }

    return Material(
      color: color,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: kTextColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Button to jump to the tracking page
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingPage(orderId: order.id),
                  ),
                );
              },
              child: const Text(
                'TRACK',
                style: TextStyle(
                    color: kTextColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}