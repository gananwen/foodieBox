import 'package:flutter/material.dart';
import '../../util/styles.dart'; // 🔹 Shared styles
import 'refund_detail_page.dart'; // 🔹 Refund Detail Page
import 'admin_home_page.dart'; // 🔹 Admin Home Page

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🔹 Withdrawal Data
  final List<Map<String, dynamic>> paymentData = [
    {
      'vendorName': 'W Hotel Buffet',
      'vendorId': '0001',
      'amount': 'RM250.00',
      'date': '07/12/2024',
      'isNew': true,
    },
    {
      'vendorName': 'Verona Hills',
      'vendorId': '0002',
      'amount': 'RM230.00',
      'date': '17/11/2024',
      'isNew': false,
    },
    {
      'vendorName': 'Tasty Bites',
      'vendorId': '0014',
      'amount': 'RM130.00',
      'date': '20/08/2024',
      'isNew': false,
    },
  ];

  // 🔹 Refund Case Data
  final List<Map<String, dynamic>> refundCases = [
    {
      'name': 'Maria Geller',
      'id': '0007',
      'date': '05/02/2024',
      'status': 'Rejected',
      'isNew': true,
    },
    {
      'name': 'Chandler Bing',
      'id': '0005',
      'date': '10/01/2024',
      'status': 'Pending',
      'isNew': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 🔹 Confirmation Popup
  void _showConfirmationDialog(String actionLabel, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          '$actionLabel Request',
          style: kLabelTextStyle.copyWith(color: kTextColor),
        ),
        content: Text(
          'Are you sure you want to $actionLabel this request?',
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
                SnackBar(
                    content: Text('Request $actionLabel'),
                    backgroundColor: color),
              );
            },
            child: Text('Confirm', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  // 🔹 Withdrawal Card
  Widget _buildPaymentCard(Map<String, dynamic> data) {
    final TextEditingController noteController = TextEditingController();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kYellowLight,
        border: Border.all(color: kYellowGold, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kYellowGold.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: kYellowHeaderGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined,
                    size: 28, color: kTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(data['vendorName'],
                              style: kLabelTextStyle.copyWith(fontSize: 15)),
                        ),
                        if (data['isNew'])
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kSecondaryAccentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW',
                              style: kHintTextStyle.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryActionColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('VendorID: ${data['vendorId']}',
                        style: kHintTextStyle.copyWith(fontSize: 13)),
                    Text('${data['amount']} • ${data['date']}',
                        style: kHintTextStyle.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Notes Field
          TextField(
            controller: noteController,
            maxLines: 2,
            style: kHintTextStyle.copyWith(fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Notes',
              hintStyle: kHintTextStyle.copyWith(color: Colors.black45),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: kYellowMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: kYellowMedium),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kPrimaryActionColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () =>
                      _showConfirmationDialog('Decline', kPrimaryActionColor),
                  child: Text('Decline',
                      style: kLabelTextStyle.copyWith(
                          fontSize: 13, color: kPrimaryActionColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellowGold,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () =>
                      _showConfirmationDialog('Approve', Colors.green.shade700),
                  child: Text('Approve',
                      style: kLabelTextStyle.copyWith(
                          fontSize: 13, color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Refund Case Card
  Widget _buildRefundCaseCard(Map<String, dynamic> caseData) {
    final isNew = caseData['isNew'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefundDetailPage(refundData: caseData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCardColor,
          border: Border.all(color: kYellowGold, width: 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: kYellowSoft.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kProfileHeaderGradient,
                    ),
                    child: const Icon(Icons.person_outline,
                        color: kTextColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(caseData['name'],
                                style: kLabelTextStyle.copyWith(fontSize: 16)),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kSecondaryAccentColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('NEW',
                                    style: kHintTextStyle.copyWith(
                                        fontSize: 10,
                                        color: kPrimaryActionColor,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('OrderID: ${caseData['id']}',
                            style: kHintTextStyle.copyWith(fontSize: 13)),
                        Text('Issued: ${caseData['date']}',
                            style: kHintTextStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),

              // 🔹 Divider (fixed color)
              const Divider(
                height: 22,
                thickness: 0.8,
                color: Colors.black26,
              ),

              // 🔹 Buttons (optional since the card is now tappable)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      // Optional: keep eye button as quick-view popup
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: kCardColor,
                          title: Text(
                            'Quick Info',
                            style: kLabelTextStyle.copyWith(
                                color: kPrimaryActionColor),
                          ),
                          content: Text(
                            '${caseData['name']} • ${caseData['status']}\nOrder ID: ${caseData['id']}',
                            style: kHintTextStyle.copyWith(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close',
                                  style: kLinkTextStyle.copyWith(
                                      color: kPrimaryActionColor)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        color: kPrimaryActionColor),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      _showConfirmationDialog('Delete', Colors.red);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: kPrimaryActionColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Build Tab Content
  Widget _buildTabContent(String type) {
    if (type == 'Withdrawal') {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pending Requests',
              style: kLabelTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryActionColor)),
          const SizedBox(height: 10),
          ...paymentData.map((d) => _buildPaymentCard(d)).toList(),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Refund Requests',
              style: kLabelTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryActionColor)),
          const SizedBox(height: 10),
          ...refundCases.map((r) => _buildRefundCaseCard(r)).toList(),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Colors.white),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        title: const Text(
          'Payment Management',
          style: TextStyle(color: kTextColor, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kPrimaryActionColor,
              indicatorWeight: 2,
              labelColor: kPrimaryActionColor,
              unselectedLabelColor: Colors.black54,
              labelStyle: kLabelTextStyle.copyWith(fontSize: 14),
              unselectedLabelStyle: kHintTextStyle.copyWith(fontSize: 14),
              tabs: const [
                Tab(text: 'Withdrawal'),
                Tab(text: 'Refund Case'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('Withdrawal'),
          _buildTabContent('Refund'),
        ],
      ),
    );
  }
}

// ---------------- For Standalone Testing ----------------
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PaymentPage(),
  ));
}
