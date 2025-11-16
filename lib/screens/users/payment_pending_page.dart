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
    _orderStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots();
  }

  void _navigate(OrderModel order) {
    if (order.status == 'Received') {
      // ADMIN APPROVED!
      if (widget.orderType == CheckoutType.delivery) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(
              address: order.address,
              // FIX: Ensure LatLng is used correctly
              location: LatLng(order.lat, order.lng), 
              total: order.total,
              promoLabel: order.promoLabel ?? order.voucherLabel ?? '',
              orderId: order.id,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        // Pickup Order
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PickupConfirmationPage(
              orderId: order.id,
              pickupId: widget.pickupId ?? 'N/A',
              vendorName: widget.vendorName ?? 'Store',
              vendorAddress: widget.vendorAddress ?? 'Address',
              total: widget.total ?? order.total,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } else if (order.status == 'Rejected') {
      // ADMIN REJECTED!
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OrderFailurePage(
            rejectionReason: order.adminRejectionReason,
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

          // We have data, let's process it
          final order = OrderModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          // Check if status has changed and navigate
          if (order.status == 'Received' || order.status == 'Rejected') {
            // Use addPostFrameCallback to navigate after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigate(order);
            });
          }

          // Show pending UI
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryActionColor),
                  const SizedBox(height: 32),
                  // FIX: Removed const keyword
                  Text(
                    'Payment Uploaded!',
                    style: kLabelTextStyle.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your order is pending approval from the admin. This page will update automatically.',
                    style: kHintTextStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Icon(Icons.admin_panel_settings_outlined,
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