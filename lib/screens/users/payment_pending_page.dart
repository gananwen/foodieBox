import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/enums/checkout_type.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/screens/users/order_confirmation_page.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:foodiebox/screens/users/pickup_confirmation_page.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class PaymentPendingPage extends StatefulWidget {
  final String orderId;
  final CheckoutType orderType;
  
  // These are passed through for the final confirmation page
  final String? pickupId;
  final String? vendorName;
  final String? vendorAddress;
  final double? total;

  const PaymentPendingPage({
    super.key,
    required this.orderId,
    required this.orderType,
    this.pickupId,
    this.vendorName,
    this.vendorAddress,
    this.total,
  });

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  Stream<DocumentSnapshot>? _orderStream;

  @override
  void initState() {
    super.initState();
    // Start listening to the specific order document for real-time status updates
    _orderStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots();
  }

  void _navigate(OrderModel order) {
    // -----------------------------------------------------------
    // ADMIN ACTION COMPLETE: Payment is verified or rejected
    // -----------------------------------------------------------

    if (order.status == 'Payment Verified') { 
      // PAYMENT APPROVED: Customer is confirmed and can proceed to wait for fulfillment.
      
      // Determine if navigation goes to Delivery or Pickup confirmation
      if (widget.orderType == CheckoutType.delivery) {
        // DELIVERY FLOW
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(
              address: order.address ?? 'Delivery Address Not Found',
              location: LatLng(order.lat ?? 0.0, order.lng ?? 0.0), 
              total: order.total,
              promoLabel: order.promoLabel ?? order.voucherLabel ?? '',
              orderId: order.id,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        // PICKUP FLOW
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PickupConfirmationPage(
              orderId: order.id,
              pickupId: widget.pickupId ?? 'N/A',
              vendorName: widget.vendorName ?? order.vendorName ?? 'Vendor Name Not Found',
              // FIX: Ensure vendorAddress is non-null for the destination widget
              vendorAddress: widget.vendorAddress ?? order.address ?? 'Pickup Address Not Found',
              total: widget.total ?? order.total,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } else if (order.status == 'Rejected') {
      // PAYMENT REJECTED: Navigate to failure page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OrderFailurePage(
            rejectionReason: order.reviewText ?? 'Payment proof rejected by admin.', 
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Pending', style: TextStyle(color: kTextColor)),
        backgroundColor: kYellowMedium,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order status.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          // Convert Firestore Map to OrderModel
          final order = OrderModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          // Check if status has changed away from the pending state
          if (order.status == 'Payment Verified' || order.status == 'Rejected') {
            // Use addPostFrameCallback to safely navigate after the current build cycle completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigate(order);
            });
          }

          // Show pending UI while waiting for Admin action
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryActionColor),
                  const SizedBox(height: 32),
                  Text(
                    'Payment Uploaded!',
                    style: kLabelTextStyle.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your payment proof has been uploaded. It is pending verification by the Admin.',
                    style: kHintTextStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Icon(Icons.verified_user_outlined,
                      size: 80, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}