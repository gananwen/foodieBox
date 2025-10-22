import 'package:flutter/material.dart';
// Updated import path and class name for colors
import '../constants.dart';

// --- Dummy Pages for Navigation (To be replaced with your actual pages later) ---
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
// ------------------------------------------------------------------------

// --- Vendor Dashboard Page (Figure 25) ---
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

  // This state management is simplified here; navigation happens within the build method
  // or specific button handlers to manage page switching (Product, Orders, More).

  // Handlers for Bottom Nav Bar, for example:
  void _onBottomBarTapped(int index) {
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProductPage()));
        break;
      case 2:
        // TODO: Navigate to Promotions Page (Figure 32)
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
      backgroundColor: AppColors.primaryBackgroundLightest, // FEFFE1
      body: const VendorHomePageContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        backgroundColor: AppColors.whiteBase,
        selectedItemColor: AppColors.textBoundary,
        unselectedItemColor: AppColors.textBoundary.withOpacity(0.5),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Product',
          ),
          // IMPORTANT: Promotions tab is highlighted with the action color
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

// --- Separate Widget for Dashboard Content (Figure 25) ---
class VendorHomePageContent extends StatelessWidget {
  const VendorHomePageContent({super.key});

  // Reusable widget to display a single quick stat card
  Widget _buildStatCard(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.sectionBackground, // E8FFC9 for sections
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
            color: AppColors.textBoundary.withOpacity(0.1), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.textBoundary.withOpacity(0.7),
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
              color: AppColors.textBoundary,
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
          color: AppColors.sectionBackground, // E8FFC9 for sections
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
              color: AppColors.textBoundary.withOpacity(0.1), width: 1.0),
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
                      color: AppColors.textBoundary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    actionType,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBoundary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: AppColors.textBoundary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 40.0,
              color: AppColors.textBoundary.withOpacity(0.7),
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
            // --- Header/Profile Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.secondaryAccentLight, // FFFFB2
                      child: const Icon(Icons.person,
                          size: 40, color: AppColors.textBoundary),
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
                                  color: AppColors.textBoundary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textBoundary.withOpacity(0.7)),
                          ],
                        ),
                        Text(
                          'Vendor ID: $vendorId',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textBoundary.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                // Settings icon for the Settings Page (Figure 26)
                IconButton(
                  icon: const Icon(Icons.settings,
                      size: 28.0, color: AppColors.textBoundary),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBoundary),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBoundary),
            ),
            const SizedBox(height: 16.0),
            _buildActionBlock(
              'Product',
              'Expand your business',
              Icons.inventory_2_outlined,
              () {
                // Navigate to the Product Page
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
