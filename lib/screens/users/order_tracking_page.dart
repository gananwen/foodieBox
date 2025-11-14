import 'dart:async';
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
  final List<String> _steps = [
    'Order received',
    'Preparing your order',
    'Driver on the way',
    'Order delivered',
  ];

  final ValueNotifier<int> _stepNotifier = ValueNotifier(0);
  Timer? _animationTimer;
  Future<VendorModel>? _vendorFuture;
  Future<LatLng>? _vendorLatLngFuture;

  // Fixed demo driver
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
    _startDemoTimer();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _stepNotifier.dispose();
    super.dispose();
  }

  void _startDemoTimer() {
    _animationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_stepNotifier.value < _steps.length - 1) {
        _stepNotifier.value++;
      } else {
        timer.cancel();
        _onDemoFinished();
      }
    });
  }

  void _onDemoFinished() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RateDriverPage(
          driver: fixedDriver,
          orderId: widget.orderId, // <-- pass orderId
        ),
      ),
    );
  }

  Future<VendorModel> _fetchVendor(String vendorId) async {
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
            return const Center(child: Text('Order not found.'));
          }

          final order = OrderModel.fromMap(
              orderSnapshot.data!.data() as Map<String, dynamic>,
              orderSnapshot.data!.id);

          // --- FIX: Check for null lat/lng ---
          // This happens if it's a pickup order
          if (order.lat == null || order.lng == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Tracking is not available for this pickup order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }
          
          // If not null, we can safely use '!'
          final LatLng userLocation = LatLng(order.lat!, order.lng!);
          // --- END FIX ---


          if (order.items.isEmpty) {
            return const Center(child: Text('Order has no items.'));
          }

          if (_vendorFuture == null) {
            _vendorFuture = _fetchVendor(order.items.first.vendorId);
            _vendorLatLngFuture = _vendorFuture!
                .then((vendor) => _getVendorLatLng(vendor.storeAddress));
          }

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
                ValueListenableBuilder<int>(
                  valueListenable: _stepNotifier,
                  builder: (context, step, _) {
                    return Container(
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
                            _steps[step],
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          _buildTimeline(step),
                          const Divider(height: 32),
                          if (step >= 2) _buildDriverInfo(fixedDriver),
                          if (step >= 2) const Divider(height: 32),
                          _buildOrderSummary(order.items, order.total),
                        ],
                      ),
                    );
                  },
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

  Widget _buildTimeline(int currentStep) {
    final icons = [
      Icons.receipt_long,
      Icons.outdoor_grill,
      Icons.two_wheeler,
      Icons.home,
    ];

    return Column(
      children: List.generate(_steps.length, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

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
                    icons[index],
                    color: isActive ? Colors.black : Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                if (index < _steps.length - 1)
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
                  _steps[index],
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