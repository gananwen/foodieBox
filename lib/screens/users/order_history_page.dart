import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/screens/users/order_tracking_page.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:foodiebox/widgets/base_page.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 10),
            child: Text(
              'My Orders',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: kTextColor),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ongoing'),
              Tab(text: 'History'),
            ],
            labelColor: kPrimaryActionColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryActionColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(context, isOngoing: true, userId: _userId),
                _buildOrderList(context, isOngoing: false, userId: _userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOrderList(BuildContext context,
      {required bool isOngoing, String? userId}) {
    // --- FIX: Add new pickup status to ongoing list ---
    final ongoingStatuses = [
      'received',
      'preparing',
      'delivering',
      'pending',
      'paid_pending_pickup' // <-- ADDED
    ];
    // --- END FIX ---
    
    final historyStatuses = ['completed', 'cancelled'];

    if (userId == null) {
      return const Center(
        child: Text('Please log in to view your orders.', style: kHintTextStyle),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status',
            whereIn: isOngoing ? ongoingStatuses : historyStatuses)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryActionColor));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('An error occurred.', style: kHintTextStyle));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
                  isOngoing
                      ? 'No ongoing orders found.'
                      : 'No past orders found.',
                  style: kHintTextStyle));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          children: snapshot.data!.docs.map((doc) {
            final order =
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return _buildOrderCard(context, order, isOngoing: isOngoing);
          }).toList(),
        );
      },
    );
  }
  Widget _buildOrderCard(BuildContext context, OrderModel order,
      {required bool isOngoing}) {
    final String statusText =
        order.status[0].toUpperCase() + order.status.substring(1);
    final TextStyle statusStyle = _getStatusStyle(order.status);
    final String formattedDateTime =
        _formatDateTime(order.timestamp.toDate());

    return GestureDetector(
      // --- FIX: Only allow tap to track for delivery orders ---
      onTap: () {
        if (isOngoing && order.orderType == 'Delivery') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingPage(orderId: order.id),
            ),
          );
        }
      },
      // --- END FIX ---
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(order.vendorName,
                      style: kLabelTextStyle.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusStyle.color?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText, style: statusStyle.copyWith(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(formattedDateTime,
                style: kHintTextStyle.copyWith(fontSize: 13)),
            
            // --- FIX: Check if address is null before showing it ---
            if (order.address != null && order.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(order.address!,
                    style: kHintTextStyle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            // --- END FIX ---

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: RM${order.total.toStringAsFixed(2)}',
                    style: kLabelTextStyle.copyWith(fontSize: 15)),
                
                // --- FIX: Show correct icon for delivery or pickup ---
                if (order.orderType == 'Delivery' && order.driverId != null && isOngoing)
                  const Icon(Icons.local_shipping,
                      color: kPrimaryActionColor, size: 20),

                if (order.orderType == 'Pickup' && isOngoing)
                  const Icon(Icons.store, // Icon for pickup
                      color: kPrimaryActionColor, size: 20),
                // --- END FIX ---
              ],
            ),
          ],
        ),
      ),
    );
  }
  TextStyle _getStatusStyle(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'delivering':
        color = Colors.orange;
        break;
      case 'preparing':
        color = Colors.amber;
        break;
      // --- FIX: Add new status color ---
      case 'paid_pending_pickup':
        color = Colors.blue;
        break;
      // --- END FIX ---
      case 'received':
      case 'pending':
      default:
        color = kPrimaryActionColor;
        break;
    }
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color);
  }

  String _formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy, hh:mm a');
    return formatter.format(date);
  }
}