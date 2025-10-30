import 'package:flutter/material.dart';
import '../../util/styles.dart'; // 🔹 Your shared style file
import 'rating_page.dart'; // 🔹 Import the rating page

class DisputePage extends StatefulWidget {
  const DisputePage({super.key});

  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> reviewData = [
    {
      'vendorName': 'The Green Leaf Cafe',
      'orderId': '0020',
      'customer': 'Sophie Hart',
      'rating': 4,
      'feedback':
          'The paper bag didn’t close properly, but the items still in good condition. The delivery also take more time than it should be…',
      'status': 'Open',
    },
    {
      'vendorName': 'Urban Coffee House',
      'orderId': '0018',
      'customer': 'Liam Johnson',
      'rating': 2,
      'feedback': 'Coffee was cold and packaging was leaking.',
      'status': 'Pending',
    },
    {
      'vendorName': 'Spice Garden',
      'orderId': '0012',
      'customer': 'Maria Lopez',
      'rating': 3,
      'feedback': 'Food was okay, but service could improve.',
      'status': 'Resolved',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Color mapping for statuses
  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.orange.shade600;
      case 'Pending':
        return Colors.blue.shade600;
      case 'Resolved':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStarRating(int stars) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: index < stars ? Colors.amber : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor & Order Info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined,
                    color: Colors.black45, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['vendorName'],
                        style: kLabelTextStyle.copyWith(fontSize: 16)),
                    Text('OrderID #${review['orderId']}',
                        style: kHintTextStyle.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Customer Info + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFDADADA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.black54, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['customer'],
                        style: kLabelTextStyle.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    _buildStarRating(review['rating']),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Feedback text
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review['feedback'],
              style: kHintTextStyle.copyWith(
                color: Colors.black87,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Confirmation dialog before actions
  void _showConfirmationDialog(String actionLabel, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(actionLabel,
                style: kLabelTextStyle.copyWith(
                    fontSize: 16, color: Colors.black)),
          ],
        ),
        content: Text(
          'Are you sure you want to $actionLabel?',
          style: kHintTextStyle.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$actionLabel confirmed')),
              );
            },
            child: Text('Confirm', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _showConfirmationDialog(label, icon, color),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: kLabelTextStyle.copyWith(
                      fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String status) {
    final filtered = reviewData.where((r) => r['status'] == status).toList();

    if (filtered.isEmpty) {
      return Center(
          child: Text('No $status reviews found.',
              style: kHintTextStyle.copyWith(fontSize: 14)));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Review Details',
            style: kLabelTextStyle.copyWith(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildReviewCard(filtered.first),
        const SizedBox(height: 20),
        Text('Moderation Actions',
            style: kLabelTextStyle.copyWith(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildActionButton(Icons.delete_outline, 'Delete Review', Colors.red),
        _buildActionButton(Icons.visibility_off_outlined, 'Hide Review',
            Colors.orange.shade700),
        _buildActionButton(
            Icons.warning_amber_outlined, 'Warn Vendor', Colors.amber.shade800),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: kTextColor, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LowRatingsPanel()),
            );
          },
        ),
        title: const Text(
          'Review Moderation',
          style: TextStyle(color: kTextColor, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 1.5,
            labelStyle: kHintTextStyle.copyWith(
                fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: kHintTextStyle.copyWith(
                fontSize: 14, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Open'),
              Tab(text: 'Pending'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('Open'),
          _buildTabContent('Pending'),
          _buildTabContent('Resolved'),
        ],
      ),
    );
  }
}

// ------------------ For Standalone Testing ------------------
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DisputePage(),
  ));
}
