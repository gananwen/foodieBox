import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'orders_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order = {
    'id': '#1111',
    'vendor': 'Jaya Grocer',
    'date': 'May 15, 2024',
    'customer': 'Afsar Hossen',
    'rider': 'Mark Johnson',
    'items': [
      {'name': 'Bell Pepper Red', 'qty': 1, 'price': 2.99},
      {'name': 'Egg Chicken', 'qty': 1, 'price': 2.99},
      {'name': 'Organic Bananas', 'qty': 1, 'price': 3.99},
    ],
    'subtotal': 16.97,
    'discount': -7.00,
    'deliveryFee': 5.00,
    'deliveryDiscount': -3.00,
    'statusText': 'Delivered',
    'statusDate': 'May 15, 2024 · 1:30 PM',
  };

  OrderDetailsPage({super.key});

  // 🔹 Info field for top details
  Widget _InfoField({required String label, required String value}) {
    return Container(
      height: 47,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: kHintTextStyle.copyWith(
                  color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style:
                  kHintTextStyle.copyWith(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  // 🔹 Item row
  Widget _ItemRow(
      {required String name, required int qty, required double price}) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$name x$qty',
              style: kHintTextStyle.copyWith(
                  color: Colors.grey.shade700, fontSize: 13)),
          Text('RM ${price.toStringAsFixed(2)}',
              style:
                  kHintTextStyle.copyWith(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  // 🔹 Status box
  Widget _StatusBox({required String statusText, required String date}) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText,
                  style: kHintTextStyle.copyWith(
                      color: Colors.black87, fontSize: 13)),
              Text(date,
                  style: kHintTextStyle.copyWith(
                      color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Summary Row
  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: kHintTextStyle.copyWith(
                  color: Colors.grey.shade700, fontSize: 13)),
          Text(
            (value >= 0 ? 'RM' : '-RM') + value.abs().toStringAsFixed(2),
            style: kHintTextStyle.copyWith(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = order['subtotal'] +
        order['discount'] +
        order['deliveryFee'] +
        order['deliveryDiscount'];

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kCardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrdersPage()),
            );
          },
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
              color: kTextColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      // 🔹 Body
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ${order['id']}',
                      style: kHintTextStyle.copyWith(
                          fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 10),

                  // Info fields
                  _InfoField(label: 'Order Date', value: order['date']),
                  _InfoField(label: 'Vendor', value: order['vendor']),
                  _InfoField(label: 'Customer', value: order['customer']),
                  _InfoField(label: 'Driver', value: order['rider']),
                  const SizedBox(height: 14),

                  // Items
                  Text('Items',
                      style: kHintTextStyle.copyWith(
                          color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...order['items'].map<Widget>((item) {
                    return _ItemRow(
                        name: item['name'],
                        qty: item['qty'],
                        price: item['price']);
                  }).toList(),

                  const SizedBox(height: 14),

                  // Summary
                  Text('Summary',
                      style: kHintTextStyle.copyWith(
                          color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Subtotal', order['subtotal']),
                  _buildSummaryRow('Total discount', order['discount']),
                  _buildSummaryRow('Standard delivery', order['deliveryFee']),
                  _buildSummaryRow(
                      'Delivery fee discount', order['deliveryDiscount']),
                  _buildSummaryRow('Total', total),

                  const SizedBox(height: 14),

                  // Status
                  Text('Status',
                      style: kHintTextStyle.copyWith(
                          color: Colors.black87, fontSize: 14)),
                  _StatusBox(
                      statusText: order['statusText'],
                      date: order['statusDate']),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 🔹 Divider + Buttons section (Raised and themed)
          Container(
            decoration: BoxDecoration(
              color: kCardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full-width divider
                Divider(
                  color: kPrimaryActionColor.withOpacity(0.4),
                  thickness: 0.8,
                  height: 0,
                ),
                const SizedBox(height: 20),

                // Buttons with internal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: kPrimaryActionColor, width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Contact Customer',
                              style: kHintTextStyle.copyWith(
                                  color: kPrimaryActionColor,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: kPrimaryActionColor, width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Contact Vendor',
                              style: kHintTextStyle.copyWith(
                                  color: kPrimaryActionColor,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
