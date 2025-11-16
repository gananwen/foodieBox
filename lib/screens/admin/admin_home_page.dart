import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/admin_login.dart';
import 'vendor_management_page.dart';
import 'promotions_page.dart';
import 'rating_page.dart';
import 'report_page.dart';
import 'order_approvals_page.dart';
import 'profile_page.dart';
import 'settings/setting_page.dart';

// ================= ADMIN HOMEPAGE =================
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // 🔥 INLINE COLOR THEME DEFINITION
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _accentIndigo = Color(0xFF5C6BC0);
  static const Color _backgroundGray = Color(0xFFF4F6F9);
  static const Color _cardWhite = Colors.white;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _chartCyan = Color(0xFF00ACC1);

  bool _isLoading = true;

  // Stats
  int totalVendors = 0;
  int ordersToday = 0;
  int totalDrivers = 0;
  int disputes = 0;
  int activeVouchersCount = 0;

  // Charts
  List<_ChartData> weeklyRevenue = [];
  List<_ChartData> weeklyOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ------------------------------------------------------------
  // 🔥 DATA FETCH LOGIC
  // ------------------------------------------------------------
  Future<void> _fetchDashboardData() async {
    try {
      final vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendors').get();
      totalVendors = vendorsSnapshot.docs.length;

      final driversSnapshot =
          await FirebaseFirestore.instance.collection('drivers').get();
      totalDrivers = driversSnapshot.docs.length;

      final vouchersSnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('active', isEqualTo: true)
          .get();
      activeVouchersCount = vouchersSnapshot.docs.length;

      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)).copyWith(
            hour: 23,
            minute: 59,
            second: 59,
          );

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      Map<String, double> revenueMap = {
        "Mon": 0,
        "Tue": 0,
        "Wed": 0,
        "Thu": 0,
        "Fri": 0,
        "Sat": 0,
        "Sun": 0,
      };
      Map<String, int> orderMap = {
        "Mon": 0,
        "Tue": 0,
        "Wed": 0,
        "Thu": 0,
        "Fri": 0,
        "Sat": 0,
        "Sun": 0,
      };

      ordersToday = 0;
      disputes = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp;
        final date = ts.toDate();
        final day = _getDayOfWeek(date.weekday);

        double total =
            (data['total'] is num) ? (data['total'] as num).toDouble() : 0;
        revenueMap[day] = revenueMap[day]! + total;
        orderMap[day] = orderMap[day]! + 1;

        if (date.day == now.day &&
            date.month == now.month &&
            date.year == now.year) {
          ordersToday++;
          if ((data['status'] ?? '') == 'dispute') disputes++;
        }
      }

      weeklyRevenue =
          revenueMap.entries.map((e) => _ChartData(e.key, e.value)).toList();
      weeklyOrders = orderMap.entries
          .map((e) => _ChartData(e.key, e.value.toDouble()))
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching dashboard: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      default:
        return "Sun";
    }
  }

  // ------------------------------------------------------------
  // UI BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 700
            ? 3
            : 2;

    final childAspectRatio = crossAxisCount == 2
        ? 1.3
        : crossAxisCount == 3
            ? 1.5
            : 1.6;

    return Scaffold(
      backgroundColor: _backgroundGray,
      drawer: const _AdminDrawer(),
      appBar: AppBar(
        backgroundColor: _cardWhite,
        elevation: 1,
        title: const Text(
          "Admin Dashboard 📈",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: _textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text("Key Performance Indicators",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _StatCard(
                        title: "Total Vendors",
                        value: totalVendors.toString(),
                        icon: Icons.store_mall_directory_rounded,
                        color: _primaryBlue.withOpacity(0.9),
                        change: "+10%",
                      ),
                      _StatCard(
                        title: "Orders Today",
                        value: ordersToday.toString(),
                        icon: Icons.shopping_basket_rounded,
                        color: _chartCyan.withOpacity(0.9),
                        change: "+5%",
                      ),
                      _StatCard(
                        title: "Total Drivers",
                        value: totalDrivers.toString(),
                        icon: Icons.delivery_dining_rounded,
                        color: _accentIndigo.withOpacity(0.9),
                        change: "+3%",
                      ),
                      _StatCard(
                        title: "Active Vouchers",
                        value: activeVouchersCount.toString(),
                        icon: Icons.local_activity_rounded,
                        color: Colors.green.shade700,
                        change: "+1%",
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: "Weekly Revenue (USD) 💰"),
                  _ChartContainer(
                      height: 250,
                      child: _buildBarChart(
                          weeklyRevenue, _primaryBlue, 'Revenue')),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: "Weekly Orders Count 📦"),
                  _ChartContainer(
                      height: 250,
                      child:
                          _buildBarChart(weeklyOrders, _chartCyan, 'Orders')),
                ],
              ),
            ),
    );
  }

  // ---------------- Charts ----------------
  Widget _buildBarChart(List<_ChartData> data, Color color, String type) {
    double maxY = data.isNotEmpty
        ? data.map((d) => d.value).reduce((a, b) => a > b ? a : b)
        : 10;
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;
    double interval = maxY / 4 < 1 ? 1 : (maxY / 4).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x.toInt()].day}\n',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: type == 'Revenue'
                        ? '\$${rod.toY.toStringAsFixed(2)}'
                        : rod.toY.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    color: color,
                    width: 14,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4)),
                  )
                ]))
            .toList(),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                String text = type == 'Revenue'
                    ? '\$${value.toInt()}'
                    : value.toInt().toString();
                return Text(text,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    textAlign: TextAlign.left);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    data[value.toInt() % 7].day,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _textMuted),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}

// =================== DATA MODELS ===================
class _ChartData {
  final String day;
  final double value;
  _ChartData(this.day, this.value);
}

// =================== RESPONSIVE STAT CARD ===================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = change.contains('+');

    return LayoutBuilder(
      builder: (context, constraints) {
        double scaleFactor = constraints.maxHeight / 120;
        if (scaleFactor > 1) scaleFactor = 1;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _AdminHomePageState._cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(title,
                          style: TextStyle(
                              color: _AdminHomePageState._textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12 * scaleFactor)),
                    ),
                  ),
                  Icon(icon, color: color, size: 20 * scaleFactor),
                ],
              ),
              SizedBox(height: 6 * scaleFactor),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                          color: _AdminHomePageState._textDark,
                          fontSize: 28 * scaleFactor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${isPositive ? '↑' : '↓'} $change vs last week',
                    style: TextStyle(
                        color: isPositive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12 * scaleFactor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =================== CHART CONTAINER ===================
class _ChartContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const _ChartContainer({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdminHomePageState._cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// =================== SECTION TITLE ===================
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AdminHomePageState._textDark)),
    );
  }
}

// ================== DRAWER WIDGET ==================
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _AdminHomePageState._cardWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDrawerHeader(),
              const SizedBox(height: 16),
              const Divider(
                  height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _drawerSectionTitle("Main Menu"),
                      _DrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: "Dashboard",
                        onTap: () => Navigator.pop(context),
                        isActive: true,
                      ),
                      _DrawerItem(
                        icon: Icons.people_alt_rounded,
                        title: "Vendor Management",
                        onTap: () =>
                            _navigateTo(context, const VendorManagementPage()),
                      ),
                      _DrawerItem(
                        icon: Icons.campaign_rounded,
                        title: "Promotions & Vouchers",
                        onTap: () =>
                            _navigateTo(context, const PromotionsAdminPage()),
                      ),
                      _DrawerItem(
                        icon: Icons.payment_rounded,
                        title: "Order Approvals",
                        onTap: () =>
                            _navigateTo(context, const OrderApprovalsPage()),
                      ),
                      _DrawerItem(
                        icon: Icons.reviews_rounded,
                        title: "Ratings & Moderation",
                        onTap: () => _navigateTo(context,
                            LowRatingsPanel(adminId: "currentAdminId")),
                      ),
                      _DrawerItem(
                        icon: Icons.analytics_rounded,
                        title: "Analytics & Reports",
                        onTap: () => _navigateTo(context, const ReportPage()),
                      ),
                      const SizedBox(height: 24),
                      _drawerSectionTitle("Account & Settings"),
                      _DrawerItem(
                        icon: Icons.person_rounded,
                        title: "Profile",
                        onTap: () => _navigateTo(context, const ProfilePage()),
                      ),
                      _DrawerItem(
                        icon: Icons.settings_rounded,
                        title: "Settings",
                        onTap: () => _navigateTo(context, const SettingsApp()),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                  height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
              _DrawerItem(
                icon: Icons.logout_rounded,
                title: "Logout",
                onTap: () => _confirmLogout(context),
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildDrawerHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _AdminHomePageState._primaryBlue,
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("FoodieBox Admin",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _AdminHomePageState._textDark)),
              SizedBox(height: 2),
              Text("Dashboard Control",
                  style: TextStyle(
                      fontSize: 14, color: _AdminHomePageState._textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: _AdminHomePageState._textMuted)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Logout",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _AdminHomePageState._textDark)),
        content: const Text(
          "Are you sure you want to log out of the Admin Panel?",
          style: TextStyle(color: _AdminHomePageState._textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
                style: TextStyle(color: _AdminHomePageState._textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminLoginPage()));
      }
    }
  }
}

// Drawer Item widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLogout;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor =
        isLogout ? Colors.red.shade600 : _AdminHomePageState._primaryBlue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? _AdminHomePageState._primaryBlue.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon,
            color: isActive
                ? _AdminHomePageState._primaryBlue
                : _AdminHomePageState._textMuted,
            size: 24),
        title: Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isLogout ? itemColor : _AdminHomePageState._textDark)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: _AdminHomePageState._primaryBlue.withOpacity(0.05),
      ),
    );
  }
}

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const AdminHomePage(),
    routes: {
      '/admin_login': (context) => const AdminLoginPage(),
    },
  ));
}
