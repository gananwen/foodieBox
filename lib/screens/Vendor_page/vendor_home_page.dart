import 'package:flutter/material.dart';
import '../../util/styles.dart'; // Using your team's styles file

// --- 1. 导入你所有的主页面 ---
import 'product_page.dart';
import 'orders_page.dart';
import 'marketing_page.dart';

// --- Dummy Pages for Navigation ---
// SettingsPage (Figure 26) 仍然是占位符
// *** 它现在也必须接收 onBackToDashboard 函数 ***
class SettingsPage extends StatelessWidget {
  // 接收这个函数
  final VoidCallback onBackToDashboard;
  const SettingsPage({super.key, required this.onBackToDashboard});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      // 修复 AppBar
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kAppBackgroundColor,
        // 使用这个函数，而不是 Navigator.pop()
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: onBackToDashboard,
        ),
      ),
      body: const Center(child: Text('Settings Page (Figure 26) Placeholder')),
    );
  }
}
// ------------------------------------------------------------------------

// --- Vendor Dashboard Page (Figure 25) ---
// This widget is now the main "Shell" that holds the Bottom Nav Bar
class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  // We keep track of the selected index for the BottomNavigationBar
  int _currentIndex = 0;

  // --- 1. 创建一个函数来切换回 Dashboard ---
  void _goToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  // --- 2. 声明 _pages 列表 ---
  late final List<Widget> _pages;

  // --- 3. 这是底部栏和 Action 按钮都会调用的函数 ---
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // No more Navigator.push!
  }

  @override
  void initState() {
    super.initState();

    // --- 4. 在 initState 中初始化 _pages 列表 ---
    // 这样我们就可以把 _goToDashboard 和 _onTabTapped 函数传递下去
    _pages = [
      // 0. Dashboard - 把 _onTabTapped 传递给它
      VendorHomePageContent(onTabTapped: _onTabTapped),
      // 1. Product - 把 _goToDashboard 传递给它
      ProductPage(onBackToDashboard: _goToDashboard),
      // 2. Promotions
      MarketingPage(onBackToDashboard: _goToDashboard),
      // 3. Orders
      OrdersPage(onBackToDashboard: _goToDashboard),
      // 4. More (Settings)
      SettingsPage(onBackToDashboard: _goToDashboard),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor, // FEFFE1

      // --- 5. Body 现在会根据 _currentIndex 自动切换页面 ---
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // --- 6. 你的 BottomNavigationBar 保持不变 ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex, // Index is now managed correctly
        backgroundColor: kCardColor, // White
        selectedItemColor:
            _currentIndex == 2 ? kPrimaryActionColor : kTextColor,
        unselectedItemColor:
            kTextColor.withAlpha(128), // 修复: withOpacity -> withAlpha
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
        onTap: _onTabTapped, // 使用我们统一的函数
      ),
    );
  }
}

// --- Separate Widget for Dashboard Content (Figure 25) ---
class VendorHomePageContent extends StatelessWidget {
  // --- 1. 接收 onTabTapped 函数 ---
  final Function(int) onTabTapped;

  const VendorHomePageContent({super.key, required this.onTabTapped});

  // Reusable widget to display a single quick stat card
  Widget _buildStatCard(String title, dynamic value) {
    // Dummy data
    int todaysOrders = 25;
    double todaysSales = 300.00;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kSecondaryAccentColor, // E8FFC9 for sections
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
            color: kTextColor.withAlpha(26), width: 3.0), // Your 3.0 width
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: kTextColor.withAlpha(179),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            title.contains("Sales")
                ? 'RM${todaysSales.toStringAsFixed(2)}'
                : todaysOrders.toString(),
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
              color: kTextColor.withAlpha(26), width: 3.0), // Your 3.0 width
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
                      color: kTextColor.withAlpha(153),
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
                      color: kTextColor.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 40.0,
              color: kTextColor.withAlpha(179),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dummy data
    String vendorName = "Afsar Hossen";
    String vendorId = "1234";

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
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: kSecondaryAccentColor,
                      child: Icon(Icons.person, size: 40, color: kTextColor),
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
                                size: 18, color: kTextColor.withAlpha(179)),
                          ],
                        ),
                        Text(
                          'Vendor ID: $vendorId',
                          style: TextStyle(
                              fontSize: 14, color: kTextColor.withAlpha(153)),
                        ),
                      ],
                    ),
                  ],
                ),
                // --- 2. 修复 Settings 按钮 ---
                IconButton(
                  icon:
                      const Icon(Icons.settings, size: 28.0, color: kTextColor),
                  onPressed: () {
                    // "More" 按钮在索引 4
                    onTabTapped(4);
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
                _buildStatCard('Today\'s Orders', 0),
                _buildStatCard('Today\'s Sales', 0.0),
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
            // --- 3. 修复 Product 按钮 ---
            _buildActionBlock(
              'Product',
              'Expand your business',
              Icons.inventory_2_outlined,
              () {
                // "Product" 按钮在索引 1
                onTabTapped(1);
              },
            ),
            // --- 4. 修复 Orders 按钮 ---
            _buildActionBlock(
              'Orders',
              'Manage incoming requests',
              Icons.receipt_long_outlined,
              () {
                // "Orders" 按钮在索引 3
                onTabTapped(3);
              },
            ),
          ],
        ),
      ),
    );
  }
}
