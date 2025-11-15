import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../util/styles.dart';
import 'notifications_page.dart';
import '../auth/admin_login.dart';
import 'vendor_management_page.dart';
import 'promotions_page.dart';
import 'rating_page.dart';
import 'report_page.dart';
import 'subscription_page.dart';
import 'profile_page.dart';
import 'settings/setting_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int unreadNotifications = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      drawer: const _AdminDrawer(),
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 1,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: kTextColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: kTextColor),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  );
                  setState(() {
                    unreadNotifications = 0;
                  });
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth > 1000
              ? 4
              : screenWidth > 700
                  ? 3
                  : 2; // Responsive grid columns

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Stats Cards ---
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: const [
                    _StatCard(
                        title: "Total Vendors", value: "22", change: "+10%"),
                    _StatCard(title: "Orders Today", value: "9", change: "+5%"),
                    _StatCard(
                        title: "Active Deliveries", value: "4", change: "-2%"),
                    _StatCard(
                        title: "Complaints/Disputes",
                        value: "2",
                        change: "-1%"),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Charts ---
                const _SectionTitle(title: "Weekly Sales"),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: const _WeeklySalesChart(),
                ),
                const SizedBox(height: 20),

                const _SectionTitle(title: "Order Status"),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: const _OrderStatusPieChart(),
                ),
                const SizedBox(height: 20),

                const _SectionTitle(title: "Vendor Performance"),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: const _VendorPerformanceBarChart(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================== Drawer ==================
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 196, 195, 195),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 243, 241, 241),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(3, 0),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Drawer Header ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Admin Panel",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "FoodieBox",
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5, color: Colors.grey),
                const SizedBox(height: 16),

                // --- Scrollable items ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _drawerSectionTitle("Main"),
                        _DrawerItem(
                          icon: Icons.dashboard_outlined,
                          title: "Dashboard",
                          onTap: () => Navigator.pop(context),
                        ),
                        _DrawerItem(
                          icon: Icons.people_alt_outlined,
                          title: "Vendor Management",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VendorManagementPage()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.campaign_outlined,
                          title: "Promotions & Vouchers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PromotionsAdminPage()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.reviews_outlined,
                          title: "Ratings & Moderation",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LowRatingsPanel()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.analytics_outlined,
                          title: "Analytics & Reports",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportPage()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.subscriptions_outlined,
                          title: "Subscription Management",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SubscriptionApp()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _drawerSectionTitle("Others"),
                        _DrawerItem(
                          icon: Icons.person_outline,
                          title: "Profile",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfilePage()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.settings_outlined,
                          title: "Settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsApp()),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 8),
                        _DrawerItem(
                          icon: Icons.logout_outlined,
                          title: "Logout",
                          onTap: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                title: const Text("Confirm Logout",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937))),
                                content: const Text(
                                  "Are you sure you want to logout?",
                                  style: TextStyle(color: Color(0xFF4B5563)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel",
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Logout",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminLoginPage()),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280)),
      ),
    );
  }
}

// Drawer Item widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, color: const Color(0xFF374151), size: 22),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937)),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.white,
        hoverColor: Colors.grey.shade100,
      ),
    );
  }
}

// ================== Stats & Charts ==================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = change.contains('+');
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(2, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: kTextColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: kTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor),
      ),
    );
  }
}

class _WeeklySalesChart extends StatelessWidget {
  const _WeeklySalesChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _chartBoxDecoration(),
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  return Text(days[value.toInt() % 7],
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 2),
                FlSpot(1, 3.5),
                FlSpot(2, 2.5),
                FlSpot(3, 5),
                FlSpot(4, 3),
                FlSpot(5, 4.5),
                FlSpot(6, 6),
              ],
              isCurved: true,
              color: kPrimaryActionColor,
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true, color: kPrimaryActionColor.withOpacity(0.2)),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusPieChart extends StatelessWidget {
  const _OrderStatusPieChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _chartBoxDecoration(),
      padding: const EdgeInsets.all(12),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
                color: kPrimaryActionColor,
                value: 45,
                title: 'Completed',
                titleStyle: const TextStyle(fontSize: 10, color: kTextColor)),
            PieChartSectionData(
                color: kCategoryColor,
                value: 35,
                title: 'Pending',
                titleStyle: const TextStyle(fontSize: 10, color: kTextColor)),
            PieChartSectionData(
                color: Colors.amberAccent,
                value: 20,
                title: 'Cancelled',
                titleStyle: const TextStyle(fontSize: 10, color: kTextColor)),
          ],
        ),
      ),
    );
  }
}

class _VendorPerformanceBarChart extends StatelessWidget {
  const _VendorPerformanceBarChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _chartBoxDecoration(),
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const vendors = ['A', 'B', 'C', 'D', 'E'];
                  return Text(vendors[value.toInt() % 5],
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(
                x: 0,
                barRods: [BarChartRodData(toY: 8, color: kPrimaryActionColor)]),
            BarChartGroupData(
                x: 1,
                barRods: [BarChartRodData(toY: 6, color: kCategoryColor)]),
            BarChartGroupData(
                x: 2,
                barRods: [BarChartRodData(toY: 10, color: Colors.amberAccent)]),
            BarChartGroupData(
                x: 3,
                barRods: [BarChartRodData(toY: 4, color: Colors.greenAccent)]),
            BarChartGroupData(
                x: 4,
                barRods: [BarChartRodData(toY: 7, color: Colors.orangeAccent)]),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _chartBoxDecoration() {
  return BoxDecoration(
    color: kCardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black26, width: 0.8),
  );
}

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
