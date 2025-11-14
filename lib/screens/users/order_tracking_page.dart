import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:foodiebox/models/driver_model.dart';
import 'package:foodiebox/screens/users/rate_driver_page.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // --- Hardcoded Data (for Demo & Firebase prep) ---
  final LatLng storeLocation = const LatLng(3.1390, 101.6869);
  final LatLng driverLocation = const LatLng(3.1400, 101.6875);

  // This is the hardcoded data you can replace with Firebase
  final DriverModel driverDetails = DriverModel(
    id: 'D-123',
    name: 'Vlad S.',
    phone: '+60123456789',
    licensePlate: 'VBE 1234',
    imageUrl: 'assets/images/courier_vlad.png', // Make sure this asset exists
  );

  final List<Map<String, dynamic>> orderItems = [
    {
      'name': 'Tacos',
      'price': 12.49,
      'quantity': 1,
      'image': 'assets/images/tacos.png', // Use placeholder or real asset
    },
    {
      'name': 'Cheese Quesadillas',
      'price': 2.49,
      'quantity': 2,
      'image': 'assets/images/quesadillas.png', // Use placeholder or real asset
    },
  ];

  double get subtotal {
    return orderItems.fold(
        0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // --- State Management ---
  Timer? _timer;
  int _currentStep = 0; // Start at step 0
  bool _driverFound = false;

  final List<String> _steps = [
    'Order received',
    'Preparing your order',
    'Looking for driver', // This is step 2
    'Order delivered', // This is step 3
  ];

  @override
  void initState() {
    super.initState();
    _startDemoSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Important to cancel the timer
    super.dispose();
  }

  /// Simulates the order progress for the demo
  void _startDemoSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
          if (_currentStep == 2) {
            // Step 2 is "Looking for driver", we show "Driver Found"
            _driverFound = true;
          }
        });
      } else {
        // --- MODIFIED SECTION ---
        // We have reached the final step ("Order delivered")
        _timer?.cancel();

        // Navigate to the Rating Page using pushReplacement
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RateDriverPage(
                orderId: widget.orderId,
                driver: driverDetails,
              ),
            ),
          );
        }
        // --- END MODIFIED SECTION ---
      }
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. Google Map View ---
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      spreadRadius: 2)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _driverFound ? driverLocation : storeLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('store'),
                      position: storeLocation,
                      infoWindow: const InfoWindow(title: 'Taco Fiesta'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRose),
                    ),
                    if (_driverFound)
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: driverLocation,
                        infoWindow: InfoWindow(title: driverDetails.name),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                      ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Timeline & Details Card ---
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
                  // Estimated Time
                  const Text(
                    'Arrives in 25-30 mins',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  // Current Status
                  Text(
                    // --- MODIFIED ---
                    // This text now updates. When step is 2, it will show "Driver Found"
                    // (or "Looking for driver" just before).
                    _driverFound && _currentStep == 2
                        ? "Driver Found!"
                        : _steps[_currentStep],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // --- Visual Timeline ---
                  _buildTimeline(),
                  const Divider(height: 32),

                  // --- Conditional UI: Driver Info ---
                  // This appears at Step 2 ("Looking for driver") and stays
                  if (_currentStep >= 2) ...[
                    _buildDriverInfo(driverDetails),
                    const Divider(height: 32),
                  ],

                  // --- Conditional UI: Order Summary ---
                  _buildOrderSummary(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the new visual timeline
  Widget _buildTimeline() {
    // Icons for each step
    final icons = [
      Icons.receipt_long,
      Icons.outdoor_grill,
      Icons.two_wheeler,
      Icons.home,
    ];

    return Column(
      children: List.generate(_steps.length, (index) {
        bool isActive = index <= _currentStep;
        bool isCurrent = index == _currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Connector
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
                // Vertical Connector Line (hide for last item)
                if (index < _steps.length - 1)
                  Container(
                    height: 40,
                    width: 2,
                    color: isActive ? Colors.amber : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  // --- MODIFIED ---
                  // Show "Driver Found" as the text for step 2 when active
                  index == 2 && _driverFound ? "Driver Found" : _steps[index],
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

  /// Builds the driver info card
  Widget _buildDriverInfo(DriverModel driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Use a placeholder if asset fails
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: AssetImage(driver.imageUrl),
              onBackgroundImageError: (_, __) {}, // Handle image load error
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  driver.licensePlate,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            // Call Button
            IconButton(
              onPressed: () {
                // Add call logic here
              },
              icon: const Icon(Icons.call, color: Colors.green, size: 28),
            ),
            // Chat Button
            IconButton(
              onPressed: () {
                // Add chat logic here
              },
              icon: const Icon(Icons.chat_bubble, color: Colors.blue, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the order summary/subtotal section
  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtotal',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        // List of items
        ...orderItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      item['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      // Placeholder for failed image
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${item['quantity']} x ${item['name']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    'RM${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
        const Divider(height: 24),
        // Total Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'RM${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
