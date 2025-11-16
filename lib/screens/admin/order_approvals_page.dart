// FULL FILE WITH PAYMENT PROOF SUPPORT (FIXED) ----------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ImageZoomPage.dart'; // Assuming this page exists for image zoom

class OrderApprovalsPage extends StatefulWidget {
  const OrderApprovalsPage({super.key});

  @override
  State<OrderApprovalsPage> createState() => _OrderApprovalsPageState();
}

class _OrderApprovalsPageState extends State<OrderApprovalsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use a clear primary blue color for a modern feel
  static const Color _primaryColor = Color.fromARGB(255, 114, 158, 199);
  static const Color _lightPrimaryColor =
      Color(0xFFE3F2FD); // Light blue for accents

  // =======================================================================
  // Approve: deduct stock + update order status -> "Received"
  // LOGIC UNCHANGED
  // =======================================================================
  Future<void> _approveOrder(DocumentSnapshot orderDoc) async {
    final orderData = orderDoc.data() as Map<String, dynamic>? ?? {};
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
    final String? orderVendorId = orderData['vendorId'] as String?;
    final String orderId = orderDoc.id;

    final WriteBatch batch = _firestore.batch();
    final List<String> problems = [];

    try {
      // Build batch updates for each item (LOGIC UNCHANGED)
      for (var item in items) {
        final String? productId = (item['productId'] as String?)?.trim();
        final String? vendorId =
            (item['vendorId'] as String?)?.trim() ?? orderVendorId;
        final int qty = ((item['quantity'] as num?)?.toInt() ?? 0);

        if (productId == null || productId.isEmpty) {
          problems
              .add("Missing productId for item: ${item['name'] ?? 'unknown'}");
          continue;
        }
        if (vendorId == null || vendorId.isEmpty) {
          problems.add("Missing vendorId for productId: $productId");
          continue;
        }
        if (qty <= 0) {
          problems.add("Invalid quantity for productId: $productId");
          continue;
        }

        final productRef = _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('products')
            .doc(productId);

        // Use FieldValue.increment(-qty) which is atomic and safe
        batch.update(productRef, {'quantity': FieldValue.increment(-qty)});
      }

      // Update order status (part of the same batch for atomicity intent)
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'status': 'Received',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      if (!mounted) return;

      final snackMessage = problems.isEmpty
          ? "Order approved and stock deducted successfully."
          : "Order approved, but some items had issues: ${problems.join(', ')}";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage), backgroundColor: Colors.green),
      );

      // Close the order details dialog (if open)
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error approving order: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    }
  }

  // =======================================================================
  // Decline: update status -> "Rejected"
  // LOGIC UNCHANGED
  // =======================================================================
  Future<void> _declineOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Order rejected."), backgroundColor: Colors.red),
      );

      // Close the order details dialog (if open)
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rejecting order: ${e.toString()}")),
      );
    }
  }

  // =======================================================================
  // Confirmation dialog (Approve / Decline)
  // UI IMPROVED
  // =======================================================================
  Future<void> _confirmAction(DocumentSnapshot order, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("$action Order", style: TextStyle(color: _primaryColor)),
        content: Text("Are you sure you want to $action this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == "Approve" ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (action == "Approve") {
      await _approveOrder(order);
    } else {
      await _declineOrder(order.id);
    }
  }

  // =======================================================================
  // UI helpers - Cleaned up to use modern styling
  // =======================================================================
  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primaryColor),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // Stream: get orders waiting for payment proof
  // LOGIC UNCHANGED
  // =======================================================================
  Stream<QuerySnapshot> _getPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Awaiting Payment Proof')
        .snapshots();
  }

  // =======================================================================
  // View order details dialog (shows paymentProofUrl and items)
  // UI IMPROVED - Uses a full-screen-like dialog for better mobile experience
  // =======================================================================
  void _viewOrderDetails(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>? ?? {};
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final String? proofUrl = (data['paymentProofUrl'] as String?)?.trim();

    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        // Use Dialog.fullscreen for a modern, focused look
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            title: const Text("Order Details"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer/Vendor Info
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(Icons.person_outline, "Customer",
                                  data['contactName'] ?? 'N/A'),
                              _buildDetailRow(Icons.phone, "Phone",
                                  data['contactPhone'] ?? 'N/A'),
                              _buildDetailRow(
                                  Icons.store_mall_directory_outlined,
                                  "Vendor",
                                  data['vendorName'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment proof
                      Text("Payment Proof",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor)),
                      const SizedBox(height: 12),

                      if (proofUrl != null && proofUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ImageZoomPage(imageUrl: proofUrl)),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                proofUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: _lightPrimaryColor,
                                  child: Center(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                        Icon(Icons.broken_image,
                                            color: _primaryColor, size: 30),
                                        const SizedBox(height: 8),
                                        const Text("Failed to load image",
                                            style: TextStyle(
                                                color: Colors.black54)),
                                      ])),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _lightPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _primaryColor.withOpacity(0.5)),
                          ),
                          child: Text("No payment proof uploaded",
                              style: TextStyle(color: _primaryColor)),
                        ),

                      const SizedBox(height: 24),

                      // Items
                      Text("Items Ordered",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _primaryColor)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: items.map((item) {
                            final name = item['name'] ?? 'Unnamed';
                            final qty =
                                (item['quantity'] as num?)?.toString() ?? '0';
                            final price =
                                (item['price'] as num?)?.toString() ?? '0.00';
                            final imageUrl = item['imageURL'] as String?;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    (imageUrl != null && imageUrl.isNotEmpty)
                                        ? NetworkImage(imageUrl)
                                        : null,
                                backgroundColor: _lightPrimaryColor,
                                child: (imageUrl == null || imageUrl.isEmpty)
                                    ? Icon(Icons.shopping_bag_outlined,
                                        color: _primaryColor)
                                    : null,
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text("Qty: $qty"),
                              trailing: Text(
                                  "₱${double.tryParse(price) != null ? double.parse(price).toStringAsFixed(2) : price}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons (Fixed at bottom)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -3)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmAction(order, "Decline"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.thumb_down_alt_outlined),
                        label: const Text("Decline"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmAction(order, "Approve"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Approve"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // Page UI - Main order list
  // UI IMPROVED - Uses modern cards and list styling
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Order Approvals"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getPendingOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: _primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 60, color: Colors.grey[400]),
                const SizedBox(height: 10),
                const Text("No pending payment orders",
                    style: TextStyle(color: Colors.grey)),
              ],
            ));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, idx) {
              final order = orders[idx];
              final total =
                  (order['total'] as num?)?.toStringAsFixed(2) ?? "0.00";
              final vendorName = order['vendorName'] ?? 'Unknown Vendor';
              final contactName = order['contactName'] ?? 'Unknown Customer';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  onTap: () => _viewOrderDetails(order),
                  leading: CircleAvatar(
                    backgroundColor: _lightPrimaryColor,
                    child: Icon(Icons.receipt_long, color: _primaryColor),
                  ),
                  title: Text(
                    "Order #${order.id.substring(0, 8)}...",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Vendor: $vendorName",
                          style: TextStyle(color: Colors.grey[700])),
                      Text("Customer: $contactName",
                          style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "₱$total",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _primaryColor,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
