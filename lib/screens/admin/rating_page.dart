import 'package:flutter/material.dart';
import 'package:foodiebox/screens/admin/admin_home_page.dart';
import '../../util/styles.dart';
import 'dispute_page.dart';

class LowRatingsPanel extends StatefulWidget {
  const LowRatingsPanel({super.key});

  @override
  State<LowRatingsPanel> createState() => _LowRatingsPanelState();
}

class _LowRatingsPanelState extends State<LowRatingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> lowRatings = [
    {
      'name': 'Sophie Hart',
      'id': '0034',
      'date': '14/06/2025',
      'rating': 3,
      'feedback': 'Food was cold and delivery was slow.',
      'status': 'Open',
      'isNew': true,
    },
    {
      'name': 'Artie Lang',
      'id': '0014',
      'date': '03/04/2025',
      'rating': 2,
      'feedback': 'Incorrect order received.',
      'status': 'Pending',
      'isNew': false,
    },
    {
      'name': 'Dave David',
      'id': '0012',
      'date': '09/06/2024',
      'rating': 1,
      'feedback': 'Terrible service, very rude staff.',
      'status': 'Resolved',
      'isNew': false,
    },
    {
      'name': 'Maria Geller',
      'id': '0007',
      'date': '05/02/2024',
      'rating': 3,
      'feedback': 'Average experience, could be better.',
      'status': 'Open',
      'isNew': false,
    },
    {
      'name': 'Chandler Bing',
      'id': '0005',
      'date': '10/01/2024',
      'rating': 2,
      'feedback': 'Late delivery, food quality not good.',
      'status': 'Open',
      'isNew': false,
    },
  ];

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

  // 🔹 Status color
  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.green.shade600;
      case 'Pending':
        return Colors.orange.shade600;
      case 'Resolved':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  // 🔹 Star Rating
  Widget _buildStarRating(int stars) {
    return Row(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: Icon(
            index < stars ? Icons.star : Icons.star_border,
            color: index < stars ? Colors.amber : Colors.grey.shade400,
            size: 16,
          ),
        ),
      ),
    );
  }

  // 🔹 Popup Dialog (View/Delete)
  void _showPopupDialog({
    required String title,
    required Widget content,
    bool requireConfirm = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style:
              const TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        content: content,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: kTextColor))),
          if (requireConfirm)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryActionColor),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$title confirmed')));
              },
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  // 🔹 Compact Rating Card (tappable)
  Widget _buildRatingCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        // ✅ Navigate to DisputePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DisputePage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Top section: avatar + details + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Colors.black54, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                data['name'],
                                style: kLabelTextStyle.copyWith(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(data['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Order ID: ${data['id']}',
                            style: kHintTextStyle.copyWith(fontSize: 13)),
                        Text('Date: ${data['date']}',
                            style: kHintTextStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStarRating(data['rating']),
              const SizedBox(height: 6),
              Text(
                data['feedback'],
                style: kHintTextStyle.copyWith(
                  fontSize: 13,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 20, thickness: 0.5, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        color: Colors.black54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showPopupDialog(
                        title: "Rating Details",
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Customer: ${data['name']}",
                                style: kHintTextStyle),
                            Text("Order ID: ${data['id']}",
                                style: kHintTextStyle),
                            Text("Date: ${data['date']}",
                                style: kHintTextStyle),
                            const SizedBox(height: 6),
                            _buildStarRating(data['rating']),
                            const SizedBox(height: 8),
                            Text("Feedback:", style: kLabelTextStyle),
                            Text(data['feedback'],
                                style: kHintTextStyle.copyWith(
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showPopupDialog(
                        title: "Delete Confirmation",
                        content: const Text(
                          "Are you sure you want to delete this rating?",
                          style: kHintTextStyle,
                        ),
                        requireConfirm: true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Filter by tab status
  Widget _buildRatingList(String status) {
    final filtered = lowRatings.where((r) => r['status'] == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('No $status cases found.', style: kHintTextStyle),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildRatingCard(filtered[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
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
              color: kTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryActionColor,
          labelColor: kPrimaryActionColor,
          unselectedLabelColor: Colors.grey,
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

// ------------------ For Standalone Testing ------------------
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LowRatingsPanel(),
  ));
}
