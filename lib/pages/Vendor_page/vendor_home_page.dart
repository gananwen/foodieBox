import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import 'product_page.dart';
// import 'orders_page.dart';
// import 'settings_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Orders')),
      body: const Center(
          child: Text('Active Order Page (Figure 30) Placeholder')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page (Figure 26) Placeholder')),
    );
  }
}

class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  // Dummy data
  String vendorName = "Afsar Hossen";
  String vendorId = "1234";
  int todaysOrders = 25;
  double todaysSales = 300.00;

  // Handlers for Bottom Nav Bar
  void _onBottomBarTapped(int index) {
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        // THIS NOW NAVIGATES TO THE REAL PRODUCT PAGE
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProductPage()));
        break;
      case 2:
        // TODO: Navigate to Promotions Page (Figure 32)
        print('Navigate to Promotions');
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OrdersPage()));
        break;
      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor, // FEFFE1
      body: VendorHomePageContent(
        vendorName: vendorName,
        vendorId: vendorId,
        todaysOrders: todaysOrders,
        todaysSales: todaysSales,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        backgroundColor: kCardColor, // White
        selectedItemColor: kTextColor,
        unselectedItemColor: kTextColor.withOpacity(0.5),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Product',
          ),
          // IMPORTANT: Promotions tab is highlighted with the action color
          BottomNavigationBarItem(
            icon: Icon(Icons.volume_up_outlined,
                color: kPrimaryActionColor.withOpacity(0.7)),
            label: 'Promotions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        onTap: _onBottomBarTapped,
      ),
    );
  }
}

// --- Separate Widget for Dashboard Content (Figure 25) ---
class VendorHomePageContent extends StatelessWidget {
  // Pass in the data
  final String vendorName;
  final String vendorId;
  final int todaysOrders;
  final double todaysSales;

  const VendorHomePageContent({
    super.key,
    required this.vendorName,
    required this.vendorId,
    required this.todaysOrders,
    required this.todaysSales,
  });

  // Reusable widget to display a single quick stat card
  Widget _buildStatCard(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kSecondaryAccentColor, // E8FFC9 for sections
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
            color: kTextColor.withOpacity(0.1),
            width: 1.5), // Using 1.5 width as requested
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: kTextColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            title.contains("Sales")
                ? 'RM${value.toStringAsFixed(2)}'
                : value.toString(),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for action buttons (Product/Orders)
  Widget _buildActionBlock(String actionType, String description, IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: kSecondaryAccentColor, // E8FFC9 for sections
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
              color: kTextColor.withOpacity(0.1),
              width: 1.5), // Using 1.5 width as requested
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ADD NEW' == actionType ? 'ADD NEW' : 'VIEW',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: kTextColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    actionType,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: kTextColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 40.0,
              color: kTextColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Header/Profile Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: kSecondaryAccentColor, // FFFFB2
                      child:
                          const Icon(Icons.person, size: 40, color: kTextColor),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vendorName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 18, color: kTextColor.withOpacity(0.7)),
                          ],
                        ),
                        Text(
                          'Vendor ID: $vendorId',
                          style: TextStyle(
                              fontSize: 14, color: kTextColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                // Settings icon for the Settings Page (Figure 26)
                IconButton(
                  icon:
                      const Icon(Icons.settings, size: 28.0, color: kTextColor),
                  onPressed: () {
                    // Navigate to the Settings Page
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 30.0),

            // --- Quick Stats Section ---
            const Text(
              'Quick Stats',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: kTextColor),
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildStatCard('Today\'s Orders', todaysOrders),
                _buildStatCard('Today\'s Sales', todaysSales),
              ],
            ),

            const SizedBox(height: 30.0),

            // --- Actions Section ---
            const Text(
              'Actions',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: kTextColor),
            ),
            const SizedBox(height: 16.0),
            _buildActionBlock(
              'Product',
              'Expand your business',
              Icons.inventory_2_outlined,
              () {
                // THIS NOW NAVIGATES TO THE REAL PRODUCT PAGE
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProductPage()));
              },
            ),
            _buildActionBlock(
              'Orders',
              'Manage incoming requests',
              Icons.receipt_long_outlined,
              () {
                // Navigate to the Active Orders Page
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrdersPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
