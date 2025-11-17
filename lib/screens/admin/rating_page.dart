import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodiebox/screens/admin/admin_home_page.dart';
import 'dispute_page.dart';

// ⭐️ Defined Internal Styles for Modern Look ⭐️
const Color _kPrimaryActionColor = Colors.blueAccent;
const Color _kAppBackgroundColor = Color(0xFFF7F9FC); // Light background
const Color _kTextColor = Color(0xFF333333); // Dark text

const TextStyle _kLabelTextStyle =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextColor);
const TextStyle _kHintTextStyle =
    TextStyle(fontSize: 14, color: Color.fromARGB(255, 60, 59, 59));
// ⭐️ END OF INTERNAL STYLES ⭐️

class LowRatingsPanel extends StatefulWidget {
  final String adminId; // pass current admin UID for logging actions
  const LowRatingsPanel({super.key, required this.adminId});

  @override
  State<LowRatingsPanel> createState() => _LowRatingsPanelState();
}

class _LowRatingsPanelState extends State<LowRatingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔹 Stream to fetch low ratings in real-time
  Stream<List<Map<String, dynamic>>> _reviewsStream() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('rating', isLessThanOrEqualTo: 3)
        .orderBy('rating', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> reviews = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Ensure missing status field
        if (!data.containsKey('status')) {
          await doc.reference.update({'status': 'Open'});
        }

        // Fetch user email only
        String userEmail = '-';
        if (data['userId'] != null && data['userId'] != '') {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['userId'])
              .get();
          if (userDoc.exists) {
            final u = userDoc.data()!;
            userEmail = u['email'] ?? '-';
          }
        }

        // Fetch vendor email only
        String vendorEmail = '-';
        if (data['vendorId'] != null && data['vendorId'] != '') {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['vendorId'])
              .get();
          if (vendorDoc.exists) {
            final v = vendorDoc.data()!;
            vendorEmail = v['email'] ?? '-';
          }
        }

        reviews.add({
          'id': doc.id,
          'orderId': data['orderId'] ?? '',
          'userId': data['userId'] ?? '',
          'vendorId': data['vendorId'] ?? '',
          'rating': data['rating'] ?? 0,
          'feedback': data['reviewText'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          'status': data['status'] ?? 'Open',
          'userEmail': userEmail,
          'vendorEmail': vendorEmail,
        });
      }

      return reviews;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.red.shade600; // Consistent with DisputePage
      case 'Pending':
        return Colors.blue.shade600;
      case 'Resolved':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  // ⭐️ Star rating widget that supports int & double (fractional) ⭐️
  Widget _buildStarRating(double stars) {
    return Row(
      children: List.generate(5, (index) {
        if (stars >= index + 1) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (stars > index && stars < index + 1) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border, color: Colors.grey.shade400, size: 16);
        }
      }),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisputePage(
              review: data,
              adminId: widget.adminId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kAppBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline,
                        color: _kTextColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                data['userEmail'] ?? '-',
                                style: _kLabelTextStyle.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(data['status'])
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                data['status'],
                                style: TextStyle(
                                  color: _statusColor(data['status']),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Order ID: ${data['orderId']}',
                            style: _kHintTextStyle.copyWith(fontSize: 13)),
                        Text(
                            'Date: ${data['timestamp'] != null ? data['timestamp'].toString().split(' ')[0] : '-'}',
                            style: _kHintTextStyle.copyWith(fontSize: 13)),
                        Text('Vendor: ${data['vendorEmail'] ?? '-'}',
                            style: _kHintTextStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildStarRating((data['rating'] as num?)?.toDouble() ?? 0.0),
              const SizedBox(height: 8),
              Text(
                data['feedback'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _kHintTextStyle.copyWith(
                  fontSize: 13,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingList(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reviewsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _kPrimaryActionColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reviews = snapshot.data ?? [];
        final filtered = reviews.where((r) => r['status'] == status).toList();

        if (filtered.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('No $status cases found.',
                style: _kHintTextStyle.copyWith(fontSize: 16)),
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16), // Increased vertical padding
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildRatingCard(filtered[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAppBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 2, // Added slight elevation to app bar
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _kTextColor), // Changed icon to ios_new
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        title: const Text(
          'Dispute Resolution Panel',
          style: TextStyle(
              color: _kTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kPrimaryActionColor, // Blue accent
          labelColor: _kPrimaryActionColor, // Blue accent
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRatingList('Open'),
          _buildRatingList('Pending'),
          _buildRatingList('Resolved'),
        ],
      ),
    );
  }
}
