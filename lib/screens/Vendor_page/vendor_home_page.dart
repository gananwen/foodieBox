// 路径: lib/pages/vendor_home/vendor_home_page.dart
import 'package:flutter/material.dart';
import '../../util/styles.dart';

import 'product_page.dart';
import 'orders_page.dart';
import 'marketing_page.dart';
import 'more_page.dart';
import '../../repositories/vendor_data_repository.dart';
import '../../repositories/order_repository.dart';
import 'package:intl/intl.dart';

import '../../repositories/notification_repository.dart';
import '../shared/notifications_page.dart';

class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  // ... (所有变量和函数 _currentIndex, _repo, _dataFuture, initState, _reloadData, _goToDashboard, _onTabTapped 保持不变) ...
  int _currentIndex = 0;
  final VendorDataRepository _repo = VendorDataRepository();
  late Future<VendorDataBundle> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _repo.getVendorData();
  }

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
      body: FutureBuilder<VendorDataBundle>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // ... (FutureBuilder 的 loading/error/data 逻辑不变) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error loading data: ${snapshot.error}',
                    style: const TextStyle(color: kPrimaryActionColor)),
              ),
            );
          }
          if (snapshot.hasData) {
            final bundle = snapshot.data!;

            final List<Widget> pages = [
              VendorHomePageContent(onTabTapped: _onTabTapped, bundle: bundle),
              ProductPage(onBackToDashboard: _goToDashboard),
              MarketingPage(onBackToDashboard: _goToDashboard),
              OrdersPage(onBackToDashboard: _goToDashboard),
              MorePage(
                onBackToDashboard: _goToDashboard,
                bundle: bundle,
                onProfileUpdated: _reloadData,
              ),
            ];

            return IndexedStack(
              index: _currentIndex,
              children: pages,
            );
          }
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ... (BottomNavigationBar 逻辑不变) ...
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

// --- ( VendorHomePageContent ) ---

class VendorHomePageContent extends StatefulWidget {
  final Function(int) onTabTapped;
  final VendorDataBundle bundle;
  const VendorHomePageContent(
      {super.key, required this.onTabTapped, required this.bundle});

  @override
  State<VendorHomePageContent> createState() => _VendorHomePageContentState();
}

class _VendorHomePageContentState extends State<VendorHomePageContent> {
  // (所有 initState 和辅助函数 _buildStatCard, _buildActionBlock, _buildNotificationBell 保持不变)
  late OrderRepository _orderRepo;
  late Stream<Map<String, dynamic>> _statsStream;
  final _currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM');
  late NotificationRepository _notificationRepo;
  late Stream<int> _unreadCountStream;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository();
    _statsStream = _orderRepo.getTodaysStatsStream();
    _notificationRepo = NotificationRepository();
    _userRole = widget.bundle.user.role;
    _unreadCountStream = _notificationRepo.getUnreadNotificationCountStream();
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    // ... (不变)
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, size: 28.0, color: color),
          const SizedBox(height: 12.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: kTextColor.withAlpha(200),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBlock(String actionType, String description, IconData icon,
      VoidCallback onTap) {
    // ... (不变)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: kTextColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSecondaryAccentColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.0,
                color: kTextColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                      color: kTextColor.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.0,
              color: kTextColor.withAlpha(179),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    // ... (不变)
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: kTextColor, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsPage(userRole: _userRole),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.bundle.user;
    final vendor = widget.bundle.vendor;
    final String vendorName = "${user.firstName} ${user.lastName}";
    final String photoUrl = vendor.businessPhotoUrl;

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kAppBackgroundColor,
        elevation: 0,

        // --- ( ✨ 关键修复 ✨ ) ---
        centerTitle: false, // <-- 添加这一行
        // --- ( ✨ 结束修复 ✨ ) ---

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 22,
                color: kTextColor.withAlpha(180),
              ),
            ),
            Text(
              vendorName,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: kTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        titleSpacing: 20.0,
        toolbarHeight: 100,
        actions: [
          _buildNotificationBell(),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ... (所有剩下的 body 内容, _buildProfileHeader, _buildStatCard, _buildActionBlock 等都保持不变) ...
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: kTextColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kSecondaryAccentColor,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.store, size: 24, color: kTextColor)
                          : null,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.storeName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Vendor ID: ${vendor.uid.substring(0, 6)}...',
                            style: TextStyle(
                                fontSize: 13, color: kTextColor.withAlpha(153)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          size: 24.0, color: kTextColor),
                      onPressed: () => widget.onTabTapped(4), // "More"
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Quick Stats',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kTextColor),
              ),
              const SizedBox(height: 16.0),
              StreamBuilder<Map<String, dynamic>>(
                stream: _statsStream,
                builder: (context, snapshot) {
                  String formattedSales = "RM0.00";
                  String orderCount = "0";
                  Widget? overlay;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    overlay = const Center(
                        child: CircularProgressIndicator(
                      color: kPrimaryActionColor,
                      strokeWidth: 2,
                    ));
                  } else if (snapshot.hasError) {
                    formattedSales = "Error";
                    orderCount = "Error";
                    print("Stats Stream Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    orderCount = (stats['orderCount'] ?? 0).toString();
                    formattedSales =
                        _currencyFormat.format(stats['totalSales'] ?? 0.0);
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      _buildStatCard(
                        'Today\'s Orders',
                        orderCount,
                        Icons.receipt_long_outlined,
                        Colors.blue.shade300,
                      ),
                      _buildStatCard(
                        'Today\'s Sales',
                        formattedSales,
                        Icons.attach_money_outlined,
                        Colors.green.shade300,
                      ),
                      if (overlay != null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: kAppBackgroundColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: overlay,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Actions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kTextColor),
              ),
              const SizedBox(height: 16.0),
              _buildActionBlock(
                'Manage Products',
                'Add, edit, or remove items',
                Icons.inventory_2_outlined,
                () => widget.onTabTapped(1),
              ),
              const SizedBox(height: 16.0),
              _buildActionBlock(
                'Manage Orders',
                'View and process new requests',
                Icons.receipt_long_outlined,
                () => widget.onTabTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
