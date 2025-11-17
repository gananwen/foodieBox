import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

// ================= Theme & Status Colors =================
// Using a slightly more vibrant blue and gray for modern look
const Color kPrimaryColor = Color(0xFF1E88E5); // Blue 600
const Color kAccentColor = Color(0xFF607D8B); // Blue Grey 500
const Color kBackgroundColor =
    Color(0xFFF4F6F9); // Light gray background for contrast

// ================= Report Page =================
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isLoading = true;

  // WEEKLY CHARTS DATA
  List<_ChartData> revenueData = [];
  List<_ChartData> orderData = [];

  // Additional Analytics
  int _totalUsers = 0;
  int _totalVendors = 0;
  int _approvedVendors = 0;
  int _lockedVendors = 0;
  double _averageVendorRating = 0.0;

  int _totalReviews = 0;
  double _averageReviewRating = 0.0;

  int _activePromotions =
      0; // Kept in for future expansion if needed, but not fetched
  int _activeVouchers = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  // ------------------------------------------------------------
  // 🔥 MAIN FETCH METHOD (Logic remains identical)
  // ------------------------------------------------------------
  Future<void> _fetchAnalytics() async {
    try {
      // --------------------------
      // 1️⃣ Users Collection
      // --------------------------
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // --------------------------
      // 2️⃣ Orders Collection
      // --------------------------
      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();

      int totalOrderCount = ordersSnapshot.docs.length;
      double totalRevenue = 0;

      // Daily breakdown (optional, if you still want charts)
      Map<String, double> dailyRevenue = {
        "Mon": 0,
        "Tue": 0,
        "Wed": 0,
        "Thu": 0,
        "Fri": 0,
        "Sat": 0,
        "Sun": 0,
      };
      Map<String, int> dailyOrders = {
        "Mon": 0,
        "Tue": 0,
        "Wed": 0,
        "Thu": 0,
        "Fri": 0,
        "Sat": 0,
        "Sun": 0,
      };

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        double total =
            (data['total'] is num) ? (data['total'] as num).toDouble() : 0;
        totalRevenue += total;

        // Daily breakdown by timestamp if exists
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          final date = ts.toDate();
          String day = _getDayOfWeek(date.weekday);
          dailyRevenue[day] = dailyRevenue[day]! + total;
          dailyOrders[day] = dailyOrders[day]! + 1;
        }
      }

      // Build chart data
      revenueData =
          dailyRevenue.entries.map((e) => _ChartData(e.key, e.value)).toList();
      orderData = dailyOrders.entries
          .map((e) => _ChartData(e.key, e.value.toDouble()))
          .toList();

      // --------------------------
      // 3️⃣ Vendors Collection
      // --------------------------
      final vendorSnapshot =
          await FirebaseFirestore.instance.collection('vendors').get();
      _totalVendors = vendorSnapshot.docs.length;
      _approvedVendors =
          vendorSnapshot.docs.where((v) => v['isApproved'] ?? false).length;
      _lockedVendors =
          vendorSnapshot.docs.where((v) => v['isLocked'] ?? false).length;

      double vendorRatingSum = 0;
      int vendorRatingCount = 0;
      for (var v in vendorSnapshot.docs) {
        if (v.data().containsKey('rating') && v['rating'] is num) {
          vendorRatingSum += (v['rating'] as num).toDouble();
          vendorRatingCount++;
        }
      }
      _averageVendorRating =
          vendorRatingCount > 0 ? vendorRatingSum / vendorRatingCount : 0.0;

      // --------------------------
      // 4️⃣ Reviews Collection
      // --------------------------
      final reviewSnapshot =
          await FirebaseFirestore.instance.collection('reviews').get();
      _totalReviews = reviewSnapshot.docs.length;

      double sumReviews = 0;
      for (var r in reviewSnapshot.docs) {
        if (r.data().containsKey('rating') && r['rating'] is num) {
          sumReviews += (r['rating'] as num).toDouble();
        }
      }
      _averageReviewRating =
          _totalReviews > 0 ? sumReviews / _totalReviews : 0.0;

      // --------------------------
      // 5️⃣ Vouchers Collection
      // --------------------------
      final voucherSnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('active', isEqualTo: true)
          .get();
      _activeVouchers = voucherSnapshot.docs.length;

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching analytics: ${e.toString()}')),
        );
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
      case 7:
      default:
        return "Sun";
    }
  }

  // ------------------------------------------------------------
  // PDF GENERATION (Logic remains identical)
  // ------------------------------------------------------------
  Future<void> _downloadPdf() async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Analytics Report",
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(kPrimaryColor.value))),
            pw.SizedBox(height: 16),

            // Users & Vendors
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Users & Vendors Metrics",
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.Bullet(text: "Total Users: $_totalUsers"),
                    pw.Bullet(text: "Total Vendors: $_totalVendors"),
                    pw.Bullet(text: "Approved Vendors: $_approvedVendors"),
                    pw.Bullet(text: "Locked Vendors: $_lockedVendors"),
                    pw.Bullet(
                        text:
                            "Average Vendor Rating: ${_averageVendorRating.toStringAsFixed(1)}"),
                  ]),
            ),

            pw.SizedBox(height: 20),

            // Reviews & Vouchers
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Engagement Metrics",
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.Bullet(text: "Total Reviews: $_totalReviews"),
                    pw.Bullet(
                        text:
                            "Average Review Rating: ${_averageReviewRating.toStringAsFixed(1)}"),
                    pw.Bullet(text: "Active Vouchers: $_activeVouchers"),
                  ]),
            ),
          ],
        );
      },
    ));

    // Save file locally and share
    final bytes = await pdf.save();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/analytics_report.pdf');
      await file.writeAsBytes(bytes);
    } catch (e) {
      // In case path_provider fails on web/certain environments, continue to share.
    }

    // Show system print/share dialog
    await Printing.sharePdf(bytes: bytes, filename: 'analytics_report.pdf');
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Reports & Analytics 📊"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: kPrimaryColor),
            onPressed: _isLoading ? null : _downloadPdf,
            tooltip: 'Download Report PDF',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Section 1: Key Metrics (Grid Layout) ---
          const Text("Key Metrics",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),

          // Using GridView for a more modern, dashboard-like look for key stats
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.width < 400 ? 1 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                MediaQuery.of(context).size.width < 400 ? 2.5 : 1.5,
            children: [
              _metricCard("Total Users", _totalUsers.toString(),
                  Icons.people_alt, Colors.teal),
              _metricCard("Total Vendors", _totalVendors.toString(),
                  Icons.store, Colors.indigo),
              _metricCard("Approved Vendors", _approvedVendors.toString(),
                  Icons.verified, Colors.green),
              _metricCard("Locked Vendors", _lockedVendors.toString(),
                  Icons.lock, Colors.red),
              _metricCard(
                  "Avg Vendor Rating",
                  _averageVendorRating.toStringAsFixed(1),
                  Icons.star_half,
                  Colors.orange),
              _metricCard("Total Reviews", _totalReviews.toString(),
                  Icons.comment, Colors.purple),
              _metricCard(
                  "Avg Review Rating",
                  _averageReviewRating.toStringAsFixed(1),
                  Icons.star,
                  kPrimaryColor),
              _metricCard("Active Vouchers", _activeVouchers.toString(),
                  Icons.discount, Colors.pink),
            ],
          ),

          const SizedBox(height: 30),

          // --- Section 2: Weekly Revenue Chart ---
          _chartTitle("Weekly Revenue (USD) 💰", kPrimaryColor),
          _chartCard(
            SizedBox(
              height: 280,
              child: _buildBarChart(revenueData, kPrimaryColor, 'Revenue'),
            ),
          ),

          const SizedBox(height: 30),

          // --- Section 3: Weekly Order Count Chart ---
          _chartTitle("Weekly Order Count 📦", kAccentColor),
          _chartCard(
            SizedBox(
              height: 280,
              child: _buildBarChart(orderData, kAccentColor, 'Orders'),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  // Modern Stat Card (for GridView)
  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12), // smaller padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // smaller icon
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16, // smaller font
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12, // smaller font
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Title with Accent Bar
  Widget _chartTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: color,
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
      ],
    );
  }

  // Wrapper for Charts
  Widget _chartCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 0), // Adjust padding for chart
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Bar Chart Builder (Minimalist Tooltip Fix)
  Widget _buildBarChart(List<_ChartData> data, Color color, String type) {
    // Determine the max Y value for better scaling
    double maxY = data.isNotEmpty
        ? data.map((d) => d.value).reduce((a, b) => a > b ? a : b)
        : 10;
    // Add a buffer to the max Y value
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // **REMOVED:** The conflicting property (tooltipBgColor/tooltipColor/tooltipStyle)
            // The chart will now use the package's default tooltip background color.
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x.toInt()].day}\n',
                // NOTE: The text color may need adjustment if the default background is light.
                const TextStyle(
                  color: Colors
                      .white, // Keep white for now, may need to change to Colors.black if default background is light.
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: type == 'Revenue'
                        ? '\$${rod.toY.toStringAsFixed(2)}'
                        : rod.toY.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white, // Keep white for now
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
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(data[value.toInt() % 7].day,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4 < 1 ? 1 : (maxY / 4).ceilToDouble(),
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
                          topRight: Radius.circular(4))),
                ]))
            .toList(),
      ),
    );
  }
}

// ----------------------------
// DATA MODEL FOR CHARTS (No change needed)
// ----------------------------
class _ChartData {
  final String day;
  final double value;
  _ChartData(this.day, this.value);
}
