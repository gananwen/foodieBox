import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../util/styles.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrderHistoryPage> {
  String selectedCategory = 'restaurant';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kYellowMedium,
        elevation: 0,
        title: const Text('Order History', style: kLabelTextStyle),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildCategoryButton('restaurant', 'Restaurant'),
                const SizedBox(width: 12),
                _buildCategoryButton('grocery', 'Grocery'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildOrderList(selectedCategory)),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String value, String label) {
    final isSelected = selectedCategory == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedCategory = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kYellowMedium : kCardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? kTextColor : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(String category) {
    return StreamBuilder<QuerySnapshot>(
      // --- MODIFIED QUERY ---
      // This query now ONLY finds orders that are 'completed'
      // AND match the selected category.
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child:
                  Text('No order history found.', style: kHintTextStyle));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final shopName = data['shopName'] ?? 'Unknown Shop';

            // ✅ Changed 'state' to 'status' to match what we save
            final state = data['status'] ?? 'Unknown'; // Will be 'completed'

            // ✅ Made timestamp fetching safer
            final timestamp =
                (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate();
            final total = data['total'] ?? 0.0;

            final iconPath = category == 'restaurant'
                ? 'assets/order_history_food.png'
                : 'assets/order_history_trolley.png';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(iconPath, width: 40, height: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shopName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        // ✅ This will now show 'Completed' after rating
                        Text('Status: $state', style: kHintTextStyle),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(timestamp)} - ${_formatTime(timestamp)}',
                          style: kHintTextStyle,
                        ),
                      ],
                    ),
                  ),
                  Text('RM${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    // ✅ Fixed 12-hour format bug (0-hour and 12-hour)
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $suffix';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}