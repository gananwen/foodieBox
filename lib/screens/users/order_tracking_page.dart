import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/models/driver_model.dart';
import 'package:foodiebox/models/order_item.model.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/screens/users/driver_rate_page.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // --- UPDATED: Use your exact statuses ---
  // Note: We add "Delivered" as the final step
  final List<String> _steps = [
    'Order Received',
    'Preparing',
    'Ready for Pickup', // This will be skipped for delivery
    'Delivering',
    'Delivered'
  ];
  // --- END UPDATED ---

  Future<VendorModel>? _vendorFuture;
  Future<LatLng>? _vendorLatLngFuture;

  // --- REMOVED: Demo timer and ValueNotifier ---

  // Track navigation to rating page
  bool _hasNavigatedToRating = false;

  // Fixed demo driver (can be replaced with real driver from order)
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
    // --- REMOVED: Demo timer start ---
  }

  @override
  void dispose() {
    // --- REMOVED: Demo timer dispose ---
    super.dispose();
  }

  // --- NEW: Function to map status to step index ---
  int _getStepFromStatus(String status, String orderType) {
    if (orderType == 'Delivery') {
      switch (status) {
        case 'received':
          return 0;
        case 'Preparing':
          return 1;
        // Skip "Ready for Pickup" for delivery
        case 'Delivering':
          return 3; // Index 3 is 'Delivering'
        case 'completed':
          return 4; // Index 4 is 'Delivered'
        default:
          return 0;
      }
    } else {
      // Logic for 'Pickup' if it ever uses this page
      switch (status) {
        case 'received':
          return 0;
        case 'Preparing':
          return 1;
        case 'Ready for Pickup':
          return 2; // Index 2 is 'Ready for Pickup'
        case 'completed':
          return 3; 
        default:
          return 0;
      }
    }
  }
  // --- END NEW ---

  // --- NEW: Navigation function ---
  void _navigateToRatingPage(DriverModel driver, String orderId) {
    if (mounted && !_hasNavigatedToRating) {
      _hasNavigatedToRating = true; // Prevent multiple navigations
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
  // --- END NEW ---


  Future<VendorModel> _fetchVendor(String vendorId) async {
    // Find the first vendor ID from the list
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
        backgroundColor: Colors.white,
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

          // --- This page is for DELIVERY only ---
          if (order.orderType == 'Pickup' || order.lat == null || order.lng == null) {
            // Send user back if they somehow get here with a pickup order
            Navigator.of(context).pop(); 
            return const Center(child: Text('Tracking is for delivery orders.'));
          }
          
          final LatLng userLocation = LatLng(order.lat!, order.lng!);

          // --- UPDATED: Use the first vendor from the vendorIds list ---
          if (order.vendorIds.isEmpty) {
            return const Center(child: Text('Order has no vendor.'));
          }
          
          if (_vendorFuture == null) {
            _vendorFuture = _fetchVendor(order.vendorIds.first);
            _vendorLatLngFuture = _vendorFuture!
                .then((vendor) => _getVendorLatLng(vendor.storeAddress));
          }
          // --- END UPDATED ---

          // --- REAL-TIME STATUS LOGIC ---
          final int currentStep = _getStepFromStatus(order.status, order.orderType);

          // If order is marked "completed", navigate to rating page
          if (order.status == 'completed' && order.orderType == 'Delivery') {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               // Use demo driver for now, replace with 'order.driverId' when ready
               _navigateToRatingPage(fixedDriver, order.id);
             });
          }
          // --- END REAL-TIME STATUS ---

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                    return _buildMap(storeLocation, userLocation);
                  },
                ),
                const SizedBox(height: 24),
                // --- UPDATED: Pass the real currentStep ---
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
                        _steps[currentStep], // Show text for the current step
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _buildTimeline(currentStep, order.orderType),
                      const Divider(height: 32),
                      
                      // Show driver info if status is Delivering or Delivered
                      if (currentStep >= 3) _buildDriverInfo(fixedDriver),
                      if (currentStep >= 3) const Divider(height: 32),
                      
                      _buildOrderSummary(order.items, order.total),
                    ],
                  ),
                ),
                // --- END UPDATED ---
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

  Widget _buildTimeline(int currentStep, String orderType) {
    // --- UPDATED: Dynamic icons and steps for Delivery ---
    final icons = [
      Icons.receipt_long,
      Icons.outdoor_grill,
      Icons.store, // Ready for Pickup
      Icons.two_wheeler,
      Icons.home,
    ];

    List<String> stepsToShow = [];
    if (orderType == 'Delivery') {
      // Skip "Ready for Pickup"
      stepsToShow = ['Order Received', 'Preparing', 'Delivering', 'Delivered'];
    } else {
      // Skip "Delivering"
      stepsToShow = ['Order Received', 'Preparing', 'Ready for Pickup', 'Completed'];
    }
    // --- END UPDATED ---

    return Column(
      children: List.generate(stepsToShow.length, (index) {
        
        // --- UPDATED: Map timeline index to status index ---
        int stepIndex = index;
        if(orderType == 'Delivery' && index >= 2) {
           stepIndex = index + 1; // Skip step 2 ('Ready for Pickup')
        }
        // --- END UPDATED ---

        final isActive = stepIndex <= currentStep;
        final isCurrent = stepIndex == currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.amber : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icons[stepIndex], // Use the correct icon
                    color: isActive ? Colors.black : Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                if (index < stepsToShow.length - 1)
                  Container(
                    height: 40,
                    width: 2,
                    color: isActive ? Colors.amber : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  stepsToShow[index], // Use the correct step text
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

  Widget _buildOrderSummary(List<OrderItem> items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.map((item) {
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
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('RM${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}