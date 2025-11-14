import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/order_model.dart'; // <-- NEW: To read order items
import 'package:foodiebox/screens/users/main_page.dart';
import 'package:foodiebox/screens/users/order_tracking_page.dart';
import 'package:foodiebox/util/styles.dart'; // <-- NEW: For styling

class OrderConfirmationPage extends StatefulWidget {
  final String address;
  final LatLng location;
  final double total;
  final String promoLabel;
  final String orderId;

  const OrderConfirmationPage({
    super.key,
    required this.address,
    required this.location,
    required this.total,
    required this.promoLabel,
    required this.orderId,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  // To hold the list of items from the order
  Future<List<OrderItem>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the order items when the page loads
    _itemsFuture = _fetchOrderItems();
  }

  // NEW: Fetches the order from Firebase to get the item list
  Future<List<OrderItem>> _fetchOrderItems() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      if (doc.exists) {
        final order = OrderModel.fromMap(doc.data()!, doc.id);
        return order.items;
      }
      return [];
    } catch (e) {
      print('Error fetching order items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Remove the back button to prevent accidental returns
        automaticallyImplyLeading: false,
        title: const Text('Order Accepted',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          // --- MODIFIED: Center the content ---
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(), // Pushes content to the middle
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Your Order has been accepted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your items are being prepared and will be on their way soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // --- VISUALIZE: Map Preview ---
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.location,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('deliveryLocation'),
                      position: widget.location,
                    ),
                  },
                  scrollGesturesEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Address Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: kPrimaryActionColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- MORE INFO: Expandable Order Summary ---
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              // Use ExpansionTile to make it expandable
              child: ExpansionTile(
                title: const Text('Order Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: Text('Total: RM${widget.total.toStringAsFixed(2)}'),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                        .copyWith(top: 0),
                children: [
                  if (widget.promoLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Promo Applied: ${widget.promoLabel}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Show items from the future
                  FutureBuilder<List<OrderItem>>(
                    future: _itemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: kPrimaryActionColor));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No items found for this order.');
                      }

                      final items = snapshot.data!;
                      return Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text('${item.quantity}x',
                                    style: const TextStyle(
                                        color: kPrimaryActionColor,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.name)),
                                Text(
                                    'RM${(item.price * item.quantity).toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2), // Pushes buttons to the bottom
            // --- Bottom Buttons ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderTrackingPage(orderId: widget.orderId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Bottom padding
          ],
        ),
      ),
    );
  }
}