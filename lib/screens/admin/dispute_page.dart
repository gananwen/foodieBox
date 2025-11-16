import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ⭐️ Defined Internal Styles for Modern Look ⭐️
const Color _kPrimaryColor = Colors.blueAccent;
const Color _kAppBackgroundColor = Color(0xFFF7F9FC); // Light background
const Color _kTextColor = Color(0xFF333333); // Dark text

const TextStyle _kLabelTextStyle =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextColor);
const TextStyle _kHintTextStyle = TextStyle(fontSize: 14, color: Colors.grey);
// ⭐️ END OF INTERNAL STYLES ⭐️

class DisputePage extends StatefulWidget {
  final Map<String, dynamic> review;
  final String adminId; // pass current admin UID

  const DisputePage({super.key, required this.review, required this.adminId});

  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage> {
  late Map<String, dynamic> review;
  bool _loadingInfo = true;

  @override
  void initState() {
    super.initState();
    review = widget.review;
    _fetchRelatedInfo();
  }

  /// 🔹 Fetch only emails for user and vendor from users collection
  Future<void> _fetchRelatedInfo() async {
    try {
      // User email
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(review['userId'])
          .get();
      review['userEmail'] = userSnap.data()?['email'] ?? 'N/A';

      // Vendor email
      final vendorSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(review['vendorId'])
          .get();
      review['vendorEmail'] = vendorSnap.data()?['email'] ?? 'N/A';

      setState(() {
        _loadingInfo = false;
      });
    } catch (e) {
      setState(() {
        _loadingInfo = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.red.shade600; // Red for urgency/attention
      case 'Pending':
        return Colors.blue.shade600;
      case 'Resolved':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  // ⭐️ NEW: Helper to build a styled data row
  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kPrimaryColor.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text('$label:',
              style: _kLabelTextStyle.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _kLabelTextStyle.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double stars) {
    return Row(
      children: List.generate(5, (index) {
        if (stars >= index + 1) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (stars > index && stars < index + 1) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey.shade400, size: 20);
        }
      }),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Softer corners
        boxShadow: [
          // Modern, soft shadow
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _loadingInfo
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: _kPrimaryColor),
            ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor(review['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(review['status'],
                      style: TextStyle(
                          color: _statusColor(review['status']),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                // 2. Data Rows
                _buildDataRow(
                    Icons.receipt_long, 'Order ID', review['orderId']),
                _buildDataRow(
                    Icons.person_outline, 'User Email', review['userEmail']),
                _buildDataRow(
                    Icons.storefront, 'Vendor Email', review['vendorEmail']),

                const Divider(height: 24),

                // 3. Rating & Feedback
                Text('Rating:', style: _kLabelTextStyle.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                _buildStarRating((review['rating'] as num?)?.toDouble() ?? 0.0),

                const SizedBox(height: 16),

                Text('Feedback:',
                    style: _kLabelTextStyle.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kAppBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(review['feedback'],
                      style: _kHintTextStyle.copyWith(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: _kTextColor)),
                ),
              ],
            ),
    );
  }

  /// 🔹 Update status with reason & log
  Future<void> _updateStatus(String newStatus) async {
    TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reason for $newStatus', style: _kLabelTextStyle),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason for changing status',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)), // Modern border
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final docRef = FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(review['id']);

              await docRef.update({'status': newStatus});

              // Save moderation log
              await FirebaseFirestore.instance
                  .collection('moderationLogs')
                  .add({
                'reviewId': review['id'],
                'adminId': widget.adminId,
                'action': newStatus,
                'reason': reason,
                'timestamp': FieldValue.serverTimestamp(),
              });

              setState(() {
                review['status'] = newStatus;
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusColor(newStatus),
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm $newStatus'),
          ),
        ],
      ),
    );
  }

  /// 🔹 Delete review with reason & log
  Future<void> _deleteReview() async {
    TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reason for Deletion'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason for deleting review',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)), // Modern border
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(review['id'])
                    .delete();

                // Save moderation log
                await FirebaseFirestore.instance
                    .collection('moderationLogs')
                    .add({
                  'reviewId': review['id'],
                  'adminId': widget.adminId,
                  'action': 'Deleted',
                  'reason': reason,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to panel
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Deletion')),
        ],
      ),
    );
  }

  // ⭐️ NEW: Unified action button helper for a modern look
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 50), // Full width, tall button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Modern rounded corners
          ),
          elevation: 3, // Subtle lift
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Slight elevation for definition
        surfaceTintColor:
            Colors.white, // Ensures appbar doesn't inherit background tint
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Moderation',
            style: TextStyle(
                color: _kTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Details Header
            Text('Review Details',
                style: _kLabelTextStyle.copyWith(
                    fontSize: 18, color: _kPrimaryColor)),
            const SizedBox(height: 8),
            // Main Review Card
            _buildReviewCard(review),

            const SizedBox(height: 30),

            // Action Buttons Header
            Text('Moderation Actions',
                style: _kLabelTextStyle.copyWith(
                    fontSize: 18, color: _kPrimaryColor)),
            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButton(
              'Mark as Pending',
              Icons.hourglass_empty,
              Colors.blue.shade600,
              () => _updateStatus('Pending'),
            ),
            _buildActionButton(
              'Mark as Resolved',
              Icons.check_circle_outline,
              Colors.green.shade600,
              () => _updateStatus('Resolved'),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            _buildActionButton(
              'Delete Review Permanently',
              Icons.delete_forever,
              Colors.red.shade600,
              _deleteReview,
            ),
          ],
        ),
      ),
    );
  }
}
