import 'package:flutter/material.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/models/driver_model.dart';
import 'package:foodiebox/models/order_item.model.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/screens/users/driver_rate_page.dart';
import 'package:foodiebox/util/styles.dart'; // Import styles

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  
  // --- ( ✨ MODIFIED: Simplified Steps - Payment is step 0 ✨ ) ---
  // The Admin's approval directly jumps the status from 0 to 1 (Received).
  final List<String> _deliverySteps = [
    'Awaiting Payment Proof', // 0
    'Order Received',         // 1
    'Preparing',              // 2
    'Delivering',             // 3
    'Delivered'               // 4
  ];

  final List<String> _pickupSteps = [
    'Awaiting Payment Proof', // 0
    'Order Received',         // 1
    'Preparing',              // 2
    'Ready for Pickup',       // 3
    'Picked Up'               // 4
  ];
  // --- ( ✨ END MODIFICATION ✨ ) ---


  Future<VendorModel>? _vendorFuture;
  Future<LatLng>? _vendorLatLngFuture;

  bool _hasNavigatedToRating = false;

  final DriverModel fixedDriver = DriverModel(
    id: 'demo-driver',
    name: 'Slamet Rahardjo',
    phone: '012-3456789',
    licensePlate: 'WXY 1234',
    imageUrl: '',
    rating: 4.5,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- ( ✨ MODIFIED: Function to map order status to step index ✨ ) ---
  int _getStepFromStatus(String status, String orderType) {
    final lowerStatus = status.toLowerCase();
    
    // Handle aliases and ensure we jump past Awaiting Payment Proof (Step 0)
    // if status is 'Received' (Step 1).
    switch (lowerStatus) {
        case 'awaiting payment proof': return 0;
        case 'received': return 1;
        case 'paid pending pickup': return 1; // Treat as 'Received' for timeline progress
        case 'preparing': return 2;
        case 'prepared': return 2;
        case 'delivering': return 3;
        case 'ready for pickup': return 3;
        case 'delivered': return 4;
        case 'picked up': return 4;
        default: return 0;
    }
  }
  // --- ( ✨ END MODIFIED FUNCTION ✨ ) ---

  void _navigateToRatingPage(DriverModel driver, String orderId) {
    if (mounted && !_hasNavigatedToRating) {
      _hasNavigatedToRating = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RateDriverPage(
            driver: driver,
            orderId: orderId,
          ),
        ),
      );
    }
  }

  Future<VendorModel> _fetchVendor(String vendorId) async {
    if (vendorId.isEmpty) throw Exception('No vendor ID found');


    final doc = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorId)
        .get();
    if (!doc.exists) throw Exception('Vendor not found');
    return VendorModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<LatLng> _getVendorLatLng(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {}
    return const LatLng(3.1390, 101.6869); // fallback Kuala Lumpur
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Track Your Order',
            style: TextStyle(color: Colors.black)),
        backgroundColor: kAppBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, orderSnapshot) {
          if (!orderSnapshot.hasData || orderSnapshot.data?.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = OrderModel.fromMap(
              orderSnapshot.data!.data() as Map<String, dynamic>,
              orderSnapshot.data!.id);
          final bool isDelivery = order.orderType == 'Delivery';

          if (isDelivery && order.vendorIds.isEmpty) {
            return const Center(child: Text('Order has no vendor.'));
          }

          if (isDelivery && _vendorFuture == null) {
            _vendorFuture = _fetchVendor(order.vendorIds.first);
            _vendorLatLngFuture = _vendorFuture!
                .then((vendor) => _getVendorLatLng(vendor.storeAddress));
          }

          final int currentStep =
              _getStepFromStatus(order.status, order.orderType);
          
          final List<String> stepsToShow = 
              isDelivery ? _deliverySteps : _pickupSteps;

          if ((order.status == 'Delivered' || order.status == 'Picked Up') && isDelivery) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToRatingPage(fixedDriver, order.id);
            });
          }

          if (order.status.toLowerCase() == 'rejected' || order.status.toLowerCase() == 'cancelled') {
             // Navigate to Order Failure Page
             WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OrderFailurePage(
                            rejectionReason: order.adminRejectionReason ?? 'Order was ${order.status}.'
                        )
                    )
                );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Only show map for delivery
                if (isDelivery)
                  FutureBuilder<LatLng>(
                    future: _vendorLatLngFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade200,
                          ),
                          child: const Center(child: Text('Loading map...')),
                        );
                      }

                      final LatLng storeLocation = snapshot.data!;
                      final LatLng userLocation = LatLng(order.lat, order.lng);
                      return _buildMap(storeLocation, userLocation);
                    },
                  ),
                
                if (isDelivery)
                  const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepsToShow[currentStep], // Show text for the current step
                        style: kLabelTextStyle.copyWith(
                          fontSize: 22,
                          color: currentStep == 0 ? Colors.blue : kTextColor
                        ),
                      ),
                      if(order.status.toLowerCase() == 'awaiting payment proof')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Waiting for admin to approve your payment proof.',
                            style: kHintTextStyle.copyWith(fontSize: 14),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildTimeline(currentStep, order.orderType, stepsToShow),
                      const Divider(height: 32),


                      // Show driver info if status is Delivering or Delivered
                      if (isDelivery && currentStep >= 3) _buildDriverInfo(fixedDriver),
                      if (isDelivery && currentStep >= 3) const Divider(height: 32),

                      _buildOrderSummary(order), // Pass the full order model
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(LatLng storeLocation, LatLng userLocation) {
    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: storeLocation, zoom: 14),
          markers: {
            Marker(
              markerId: const MarkerId('store'),
              position: storeLocation,
              infoWindow: const InfoWindow(title: 'Store'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRose),
            ),
            Marker(
              markerId: const MarkerId('user'),
              position: userLocation,
              infoWindow: const InfoWindow(title: 'You'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  Widget _buildTimeline(int currentStep, String orderType, List<String> stepsToShow) {
  // Dynamic icons based on order type
  final List<IconData> icons;
  if (orderType == 'Delivery') {
    icons = [
      Icons.pending_actions, // Awaiting Payment Proof
      Icons.receipt_long,    // Order Received
      Icons.outdoor_grill,   // Preparing
      Icons.two_wheeler,     // Delivering
      Icons.home_filled,     // Delivered
    ];
  } else {
    icons = [
      Icons.pending_actions, // Awaiting Payment Proof
      Icons.receipt_long,    // Order Received
      Icons.outdoor_grill,   // Preparing
      Icons.store,           // Ready for Pickup
      Icons.check_circle,    // Picked Up
    ];
  }

  return Column(
    children: List.generate(stepsToShow.length, (index) {
      final isActive = index <= currentStep;
      final isCurrent = index == currentStep;

      // ✅ Force all active icons and trail colors to kYellowMedium
      final Color activeColor = kYellowMedium;
      final Color trailColor = isActive ? activeColor : Colors.grey.shade200;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: trailColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[index],
                  color: isActive ? Colors.black : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              if (index < stepsToShow.length - 1)
                Container(
                  height: 40,
                  width: 2,
                  color: trailColor,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                stepsToShow[index],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      );
    }),
  );
}

  Widget _buildDriverInfo(DriverModel driver) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              driver.imageUrl.isNotEmpty ? NetworkImage(driver.imageUrl) : null,
          child: driver.imageUrl.isEmpty
              ? const Icon(Icons.person, size: 24, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver.name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(driver.licensePlate,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  // --- MODIFIED: Order Summary to show all fees and discounts ---
  Widget _buildOrderSummary(OrderModel order) {
    
    // Determine which label to use (Promo or Voucher)
    final String? discountLabel = order.promoLabel ?? order.voucherLabel;
    final double totalDiscount = (order.discount); // Use the fixed discount field

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        // 1. Items List (Must use item price from order model, not original product price)
        ...order.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(child: Text('${item.name} x${item.quantity}')),
                Text('RM${(item.price * item.quantity).toStringAsFixed(2)}'),
              ],
            ),
          );
        }).toList(),
        
        const Divider(height: 20),

        // 2. Subtotal
        _buildSummaryRow('Subtotal', order.subtotal, isDiscount: false),
        
        // 3. Promotion/Voucher Discount
        if (totalDiscount > 0)
          _buildSummaryRow(
              discountLabel ?? 'Discount', -totalDiscount, isDiscount: true),

        // 4. Delivery Fee
        if (order.orderType == 'Delivery')
          _buildSummaryRow(
              'Delivery Fee', order.deliveryFee, isDiscount: order.deliveryFee == 0.0),

        const Divider(),
        
        // 5. Final Total
        _buildSummaryRow('Total', order.total, isBold: true, valueColor: kPrimaryActionColor),
      ],
    );
  }
  
  // Helper for cleaner summary row
  Widget _buildSummaryRow(String label, double amount,
      {bool isBold = false, bool isDiscount = false, Color? valueColor}) {
    final textColor = isDiscount ? Colors.green.shade700 : Colors.black;
    final textStyle = TextStyle(
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.bold : (isDiscount ? FontWeight.w500 : FontWeight.normal),
      color: isBold ? kTextColor : (isDiscount ? textColor : Colors.black87),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            '${amount < 0 ? '-' : ''}RM${amount.abs().toStringAsFixed(2)}',
            style: textStyle.copyWith(color: valueColor ?? textColor),
          ),
        ],
      ),
    );
  }
}