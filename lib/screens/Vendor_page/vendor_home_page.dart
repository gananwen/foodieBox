import 'package:flutter/material.dart';
import '../../util/styles.dart'; // your constants.dart

// --- Dummy Pages for Navigation ---
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
      body: const Center(
          child: Text('Product List Page (Figure 27) Placeholder')),
    );
  }
}

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

// --- Vendor Dashboard Page ---
class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  String vendorName = "Afsar Hossen";
  String vendorId = "1234";
  int todaysOrders = 25;
  double todaysSales = 300.00;

  void _onBottomBarTapped(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProductPage()));
        break;
      case 2:
        // TODO: Promotions Page
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
      backgroundColor: kAppBackgroundColor,
      body: const VendorHomePageContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        backgroundColor: kCardColor,
        selectedItemColor: kTextColor,
        unselectedItemColor: kTextColor.withOpacity(0.5),
        selectedLabelStyle: kLabelTextStyle,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volume_up_outlined),
            label: 'Promotions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        onTap: _onBottomBarTapped,
      ),
    );
  }
}

// --- Dashboard Content Widget ---
class VendorHomePageContent extends StatelessWidget {
  const VendorHomePageContent({super.key});

  Widget _buildStatCard(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kSecondaryAccentColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: kLabelTextStyle.copyWith(
              fontSize: 14,
              color: kTextColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            title.contains("Sales")
                ? 'RM${value.toStringAsFixed(2)}'
                : value.toString(),
            style: kLabelTextStyle.copyWith(
              fontSize: 24,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBlock(String actionType, String description, IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: kSecondaryAccentColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: kTextColor.withOpacity(0.1), width: 1.0),
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
                    style: kLabelTextStyle.copyWith(
                      fontSize: 12,
                      color: kTextColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    actionType,
                    style: kLabelTextStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: kLabelTextStyle.copyWith(
                        fontSize: 14, color: kTextColor.withOpacity(0.8)),
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
    String vendorName = "Afsar Hossen";
    String vendorId = "1234";
    int todaysOrders = 25;
    double todaysSales = 300.00;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: kSecondaryAccentLight,
                      child: const Icon(Icons.person,
                          size: 40, color: kTextColor),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vendorName,
                              style: kLabelTextStyle,
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 18, color: kTextColor.withOpacity(0.7)),
                          ],
                        ),
                        Text(
                          'Vendor ID: $vendorId',
                          style: kLabelTextStyle.copyWith(
                              fontSize: 14, color: kTextColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings,
                      size: 28.0, color: kTextColor),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Text(
              'Quick Stats',
              style: kLabelTextStyle.copyWith(fontSize: 20),
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
            Text(
              'Actions',
              style: kLabelTextStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16.0),
            _buildActionBlock(
              'Product',
              'Expand your business',
              Icons.inventory_2_outlined,
              () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ProductPage()));
              },
            ),
            _buildActionBlock(
              'Orders',
              'Manage incoming requests',
              Icons.receipt_long_outlined,
              () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const OrdersPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
