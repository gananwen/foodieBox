import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../util/styles.dart';
import '../../../widgets/base_page.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 0), 
            child: Text(
              'Ongoing Orders',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isNotEqualTo: 'completed')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: kPrimaryActionColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No ongoing orders found.',
                          style: kHintTextStyle));
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80), 
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final orderId = doc.id; 

                    final storeName = data['shopName'] ?? 'Unknown Store';
                    final status = data['status'] ?? 'Pending';
                    final total = (data['total'] ?? 0.0) as double;
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate() ??
                            DateTime.now();

                    final imagePath = data['shopImage'] ??
                        (data['category'] == 'restaurant'
                            ? 'assets/order_history_food.png'
                            : 'assets/order_history_trolley.png');

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Pass the REAL orderId to the tracking page
                            builder: (_) => OrderTrackingPage(orderId: orderId),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(imagePath,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  // Add errorBuilder for safety
                                  errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(storeName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kYellowLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status, // This is now dynamic
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: kPrimaryActionColor,
                                      ),
                                    ),
                                  ),
                                  Text(_formatTime(timestamp),
                                      style: kHintTextStyle),
                                ],
                              ),
                            ),
                            Text('RM${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW ---
  // Helper function to format time (copied from history page)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $suffix';
  }
}