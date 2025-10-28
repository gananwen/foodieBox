import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'admin_home_page.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> vendorOrders = [
    {'id': '#1111', 'time': '12:00 PM - 12:30 PM', 'status': 'New'},
    {'id': '#1112', 'time': '01:00 PM - 01:30 PM', 'status': 'New'},
    {'id': '#1113', 'time': '02:00 PM - 02:30 PM', 'status': 'Pending'},
  ];

  final List<Map<String, String>> customerOrders = [
    {'id': '#2111', 'time': '03:00 PM - 03:30 PM', 'status': 'New'},
    {'id': '#2112', 'time': '04:00 PM - 04:30 PM', 'status': 'Pending'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- BUILD -----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Custom Topbar — consistent with other pages
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminHomePage()),
                      );
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Active Orders',
                        style: kLabelTextStyle.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 🔹 Flat TabBar (Vendors / Customers)
            TabBar(
              controller: _tabController,
              labelColor: kPrimaryActionColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryActionColor,
              tabs: const [
                Tab(text: 'Pickup'),
                Tab(text: 'Delivery'),
              ],
            ),

            // 🔹 Tab Contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVendorsTab(),
                  _buildCustomersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB CONTENTS -----------------

  Widget _buildVendorsTab() => _buildOrderList(vendorOrders);
  Widget _buildCustomersTab() => _buildOrderList(customerOrders);

  // ---------------- ORDER LIST -----------------

  Widget _buildOrderList(List<Map<String, String>> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isNew = order['status'] == 'New';

        return Card(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(order['id']!, style: kLabelTextStyle),
            subtitle: Text(order['time']!, style: kHintTextStyle),

            // ✅ Right-side layout: status + vendor icon
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isNew ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status']!,
                    style: TextStyle(
                      color: isNew
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimaryActionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderDetailsPage()),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- POPUP DETAILS -----------------

  void _showOrderDetails(BuildContext context, Map<String, String> order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ${order['id']}',
                    style: kLabelTextStyle.copyWith(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Pickup time: ${order['time']}',
                    style: kHintTextStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Status: ${order['status']}',
                    style: kHintTextStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryActionColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Order ${order['id']} marked as done.'),
                          ),
                        );
                      },
                      child: const Text(
                        'Mark as Done',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: OrdersPage()));
}
