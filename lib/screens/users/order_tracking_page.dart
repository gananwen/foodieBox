import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final LatLng storeLocation = const LatLng(3.1390, 101.6869);
  final LatLng courierLocation = const LatLng(3.1400, 101.6875);
  bool driverFound = false;

  int currentStep = 1;

  List<String> steps = [
    'Order received',
    'Cooking your order',
    'Looking for courier',
    'Order delivered',
  ];

  void _simulateProgress() {
    if (currentStep < steps.length) {
      setState(() {
        currentStep++;
        if (currentStep >= 3) driverFound = true;
      });
    }
  }

  Widget _buildStatusStep(String label, int index) {
    final isActive = index < currentStep;
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isActive ? Colors.green : Colors.grey,
      ),
      title: Text(label),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _simulateProgress,
            tooltip: 'Simulate Progress',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🗺️ Map View
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: driverFound ? courierLocation : storeLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('store'),
                      position: storeLocation,
                      infoWindow: const InfoWindow(title: 'Taco Fiesta'),
                    ),
                    if (driverFound)
                      Marker(
                        markerId: const MarkerId('courier'),
                        position: courierLocation,
                        infoWindow: const InfoWindow(title: 'Courier Vlad'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                      ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),

            // 🕒 Timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(
                  steps.length,
                  (index) => _buildStatusStep(steps[index], index),
                ),
              ),
            ),

            const Divider(height: 30),

            // 🧑‍✈️ Courier Info
            if (driverFound)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Courier Info', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/courier_vlad.png'),
                          radius: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Vlad S.', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add call/chat logic
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Courier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 30),

            // 🍔 Store + Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/App_icons.png',
                            width: 40, height: 40),
                      ),
                      const SizedBox(width: 10),
                      const Text('Taco Fiesta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Order Summary', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('• Tacos RM12.49'),
                  const Text('• Cheese Quesadillas RM2.49'),
                  const SizedBox(height: 6),
                  const Text('Subtotal: RM14.98',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
