import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../../widgets/base_page.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  final List<Map<String, dynamic>> ongoingOrders = const [
    {
      'orderId': 'ORD123',
      'storeName': 'Jaya Grocer – DC Mall',
      'status': 'Preparing your order',
      'time': 'Nov 12, 2025 - 8:15 PM',
      'total': 14.98,
      'image': 'assets/images/jaya_dc.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 3,
      child: ListView(
        padding: const EdgeInsets.only(top: 50, bottom: 80),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Ongoing Orders',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          const SizedBox(height: 20),
          ...ongoingOrders.map((order) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderTrackingPage(orderId: order['orderId']),
                  ),
                );
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(order['image'],
                          width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['storeName'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kYellowLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order['status'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: kPrimaryActionColor,
                              ),
                            ),
                          ),
                          Text(order['time'], style: kHintTextStyle),
                        ],
                      ),
                    ),
                    Text('RM${order['total'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
