import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/screens/users/order_tracking_page.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:foodiebox/widgets/base_page.dart';
import 'package:intl/intl.dart';
import 'pickup_confirmation_page.dart';
import 'order_history_detail_page.dart';


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
        
    // --- ( ✨ UPDATED STATUSES - CASE INSENSITIVE FIX ✨ ) ---
    // We now check for both lowercase and uppercase versions
    final ongoingStatuses = [
      'received', 'Received',
      'Preparing', 'preparing',
      'Prepared', 'prepared',
      'Ready for Pickup', 'ready for pickup',
      'paid_pending_pickup',
      'Delivering', 'delivering',
    ];
    
    final historyStatuses = [
      'completed', 'Completed',
      'cancelled', 'Cancelled', // <-- This is the important fix
      'Delivered', 'delivered',
      'Picked Up', 'picked up'
    ];
    // --- ( ✨ END UPDATED STATUSES ✨ ) ---

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
          // --- ADDED: Show the index error clearly ---
          if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Database Index Required. Please create the index in your Firebase console (check the error log for the link).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
          // --- END ADDED ---
          return Center(
              child: Text('An error occurred: ${snapshot.error}', style: kHintTextStyle));
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
    // --- UPDATED: Use the status string directly, handle capitalization ---
    final String statusText = order.status.isNotEmpty
        ? order.status[0].toUpperCase() + order.status.substring(1)
        : 'Unknown';
    // --- END UPDATED ---

    final TextStyle statusStyle = _getStatusStyle(order.status);
    final String formattedDateTime =
        _formatDateTime(order.timestamp.toDate());

    return GestureDetector(
      // --- ( ✨ UPDATED NAVIGATION LOGIC ✨ ) ---
      onTap: () {
        if (isOngoing) {
          if (order.orderType == 'Delivery') {
            // Ongoing Delivery -> Track Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderTrackingPage(orderId: order.id),
              ),
            );
          } else if (order.orderType == 'Pickup') {
            // Ongoing Pickup -> QR Code Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PickupConfirmationPage(
                  orderId: order.id,
                  pickupId: order.pickupId ?? 'NA',
                  vendorName: order.vendorName ?? 'Store',
                  vendorAddress: order.vendorAddress ?? 'No address',
                  total: order.total,
                ),
              ),
            );
          }
        } else {
          // History Order (Any type) -> Details Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderHistoryDetailsPage(order: order),
            ),
          );
        }
      },
      // --- ( ✨ END UPDATED NAVIGATION LOGIC ✨ ) ---
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
                  child: Text(order.vendorName ?? 'Store', // Use safe fallback
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
            
            if (order.address != null && order.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(order.address!,
                    style: kHintTextStyle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            
            // --- ADDED: Show Pickup ID if it's a pickup order ---
            if (order.orderType == 'Pickup' && order.pickupId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Pickup ID: ${order.pickupId!}',
                    style: kHintTextStyle.copyWith(fontSize: 13, color: kPrimaryActionColor, fontWeight: FontWeight.bold)),
              ),
            // --- END ADDED ---

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: RM${order.total.toStringAsFixed(2)}',
                    style: kLabelTextStyle.copyWith(fontSize: 15)),
                
                // Show icon based on type (ongoing) or status (history)
                if (isOngoing)
                  Icon(
                    order.orderType == 'Delivery' 
                      ? Icons.local_shipping 
                      : Icons.store,
                    color: kPrimaryActionColor, 
                    size: 20
                  )
                else
                  Icon(
                    // --- ( ✨ FIX REMAINS HERE ✨ ) ---
                    // We use .toLowerCase() to make the check case-insensitive
                    order.status.toLowerCase() == 'completed' || 
                    order.status.toLowerCase() == 'delivered' || 
                    order.status.toLowerCase() == 'picked up'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                    color: 
                    // --- ( ✨ FIX REMAINS HERE ✨ ) ---
                    order.status.toLowerCase() == 'completed' || 
                    order.status.toLowerCase() == 'delivered' || 
                    order.status.toLowerCase() == 'picked up'
                      ? Colors.green
                      : Colors.red,
                    size: 20
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getStatusStyle(String status) {
    Color color;
    // --- ( ✨ UPDATED STATUS STYLES ✨ ) ---
    // This switch already uses .toLowerCase(), so it's safe!
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
      case 'picked up':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'delivering':
        color = Colors.orange;
        break;
      case 'preparing':
      case 'prepared':
        color = Colors.amber;
        break;
      case 'ready for pickup':
      case 'paid_pending_pickup':
        color = Colors.blue;
        break;
      case 'received':
      case 'pending':
      default:
        color = kPrimaryActionColor;
        break;
    }
    // --- ( ✨ END UPDATED STATUS STYLES ✨ ) ---
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color);
  }

  String _formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy, hh:mm a');
    return formatter.format(date);
  }
}