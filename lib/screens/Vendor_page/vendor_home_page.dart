import 'package:flutter/material.dart';
import '../../util/styles.dart';

// --- 1. 导入所需文件 ---
import 'product_page.dart';
import 'orders_page.dart';
import 'marketing_page.dart';
import 'more_page.dart';
import '../../repositories/vendor_data_repository.dart'; // <-- 导入 Repository
import '../../models/user.dart'; // <-- 导入 Models
import '../../models/vendor.dart'; // <-- 导入 Models

class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  int _currentIndex = 0;
  // --- 2. 为 FutureBuilder 创建 Repository 实例和 Future ---
  final VendorDataRepository _repo = VendorDataRepository();
  late Future<VendorDataBundle> _dataFuture;

  // --- 3. 在 initState 中加载数据 ---
  @override
  void initState() {
    super.initState();
    _dataFuture = _repo.getVendorData();
  }

  // --- (新增) 重新加载数据的函数 ---
  // 当我们从编辑页面返回时，我们将调用它
  void _reloadData() {
    setState(() {
      _dataFuture = _repo.getVendorData();
    });
  }

  void _goToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      // --- 4. 使用 FutureBuilder 包装你的 body ---
      body: FutureBuilder<VendorDataBundle>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // --- 状态 A: 正在加载 ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          // --- 状态 B: 出错 ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error loading data: ${snapshot.error}',
                    style: const TextStyle(color: kPrimaryActionColor)),
              ),
            );
          }
          // --- 状态 C: 成功 ---
          if (snapshot.hasData) {
            final bundle = snapshot.data!; // 这就是我们的数据！

            // 5. 将 'bundle' 传递给子页面
            final List<Widget> pages = [
              VendorHomePageContent(onTabTapped: _onTabTapped, bundle: bundle),
              ProductPage(onBackToDashboard: _goToDashboard),
              MarketingPage(onBackToDashboard: _goToDashboard),
              OrdersPage(onBackToDashboard: _goToDashboard),
              MorePage(
                onBackToDashboard: _goToDashboard,
                bundle: bundle,
                onProfileUpdated: _reloadData, // <-- 传递刷新函数
              ),
            ];

            // 6. 返回你的 IndexedStack
            return IndexedStack(
              index: _currentIndex,
              children: pages,
            );
          }
          // --- 默认状态 (不应该到这里) ---
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: kCardColor,
        selectedItemColor:
            _currentIndex == 2 ? kPrimaryActionColor : kTextColor,
        unselectedItemColor: kTextColor.withAlpha(128),
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
        onTap: _onTabTapped,
      ),
    );
  }
}

// --- (已修改) Dashboard 子 Widget ---
class VendorHomePageContent extends StatelessWidget {
  final Function(int) onTabTapped;
  final VendorDataBundle bundle; // <-- 1. 接收数据
  const VendorHomePageContent(
      {super.key, required this.onTabTapped, required this.bundle});

  Widget _buildStatCard(String title, dynamic value) {
    int todaysOrders = 25;
    double todaysSales = 300.00;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kSecondaryAccentColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(26), width: 3.0),
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
          border: Border.all(color: kTextColor.withAlpha(26), width: 3.0),
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
    // --- 2. 使用真实数据 ---
    final user = bundle.user;
    final vendor = bundle.vendor;
    final String vendorName = "${user.firstName} ${user.lastName}";
    final String vendorId = vendor.uid;
    final String photoUrl = vendor.businessPhotoUrl;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 3. (已修改) Header/Profile Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // --- (已修改) 使用真实图片 ---
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: kSecondaryAccentColor,
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.store,
                                size: 40, color: kTextColor)
                            : null,
                      ),
                      const SizedBox(width: 12.0),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- (已修改) 使用真实姓名 ---
                            Text(
                              vendorName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Vendor ID: ${vendorId.substring(0, 6)}...', // 缩短 ID
                              style: TextStyle(
                                  fontSize: 14,
                                  color: kTextColor.withAlpha(153)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.settings, size: 28.0, color: kTextColor),
                  onPressed: () => onTabTapped(4), // 跳转到 "More"
                ),
              ],
            ),
            const SizedBox(height: 30.0),
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
              () => onTabTapped(1),
            ),
            _buildActionBlock(
              'Orders',
              'Manage incoming requests',
              Icons.receipt_long_outlined,
              () => onTabTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}
