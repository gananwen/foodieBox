import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../util/styles.dart';
import 'admin_home_page.dart';

// ===================== Chart & Status Colors =====================
const Color kPrimaryColor = kPrimaryActionColor;
const Color kAccentColor = Color(0xFF6C757D);
const Color kSuccessColor = Color(0xFF4CAF50);
const Color kWarningColor = Color(0xFFFFC107);
const Color kErrorColor = Color(0xFFF44336);

// ===================== Report Model =====================
class Report {
  final String title;
  final String category;
  final DateTime createdAt;
  final String description;

  Report({
    required this.title,
    required this.category,
    required this.createdAt,
    required this.description,
  });
}

// ===================== Report Page =====================
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFilterVisible = false;

  // Filter state
  final List<String> _categories = [
    'All',
    'Sales',
    'Orders',
    'Vendors',
    'Customers'
  ];
  String _selectedCategory = 'All';
  String? _selectedDateRange;

  // Sample reports
  final List<Report> _allReports = List.generate(
    15,
    (i) {
      final categories = ['Sales', 'Orders', 'Vendors', 'Customers'];
      final category = categories[i % categories.length];
      return Report(
        title: "$category Report #${i + 1}",
        category: category,
        createdAt: DateTime.now().subtract(Duration(days: i * 2)),
        description: "Detailed information about $category report #${i + 1}.",
      );
    },
  );

  List<Report> get _filteredReports {
    return _allReports.where((report) {
      final matchCategory =
          _selectedCategory == 'All' || report.category == _selectedCategory;
      return matchCategory;
    }).toList();
  }

  void _applyFilters() => setState(() {});

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange =
            "${picked.start.day}/${picked.start.month}/${picked.start.year} - ${picked.end.day}/${picked.end.month}/${picked.end.year}";
        _applyFilters();
      });
    }
  }

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

  // 🔹 Chart Card Container
  Widget _chartCard({
    required String title,
    required Widget chart,
    VoidCallback? onDownload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            IconButton(
              icon: const Icon(Icons.download_rounded,
                  color: Colors.grey, size: 20),
              onPressed: onDownload ?? () {},
            ),
          ],
        ),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: chart,
        ),
      ],
    );
  }

  // 🔹 Analytics Tab Content (kept charts from your previous code)
  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sales & Order Reports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Sales Trend
          _chartCard(
            title: "Sales Trend",
            chart: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun'
                        ];
                        return Text(
                          months[value.toInt() % months.length],
                          style: const TextStyle(fontSize: 10),
                        );
                      }),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 1.5),
                    FlSpot(1, 1.85),
                    FlSpot(2, 2.1),
                    FlSpot(3, 1.95),
                    FlSpot(4, 2.4),
                    FlSpot(5, 2.8),
                  ],
                  isCurved: true,
                  color: kPrimaryColor,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: kPrimaryColor.withOpacity(0.15),
                  ),
                  dotData: FlDotData(show: false),
                ),
              ],
            )),
          ),

          const SizedBox(height: 28),

          // Order Volume
          _chartCard(
            title: "Order Volume",
            chart: BarChart(BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        return Text(
                          days[value.toInt() % days.length],
                          style: const TextStyle(fontSize: 10),
                        );
                      }),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(7, (i) {
                final data = [45, 62, 78, 55, 90, 110, 85];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: data[i].toDouble(),
                    color: kAccentColor,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  )
                ]);
              }),
            )),
          ),

          const SizedBox(height: 28),

          // Vendor Performance
          _chartCard(
            title: "Vendor Performance",
            chart: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: 45,
                    color: kSuccessColor,
                    title: '45%',
                    radius: 50,
                    titleStyle:
                        const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: 30,
                    color: kWarningColor,
                    title: '30%',
                    radius: 50,
                    titleStyle:
                        const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: kErrorColor,
                    title: '25%',
                    radius: 50,
                    titleStyle:
                        const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Reports Tab Content
  Widget _reportCard(Report report) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailPage(report: report),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.description, size: 28, color: kPrimaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(report.category,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              "${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsContent() {
    if (_filteredReports.isEmpty) {
      return const Center(
        child: Text("No reports found for selected filters.",
            style: TextStyle(fontSize: 14, color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        return _reportCard(_filteredReports[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Analytics & Reports",
          style: TextStyle(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isFilterVisible = !_isFilterVisible;
              });
            },
            icon: Icon(
              Icons.tune,
              color: _isFilterVisible ? kPrimaryColor : kTextColor,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryColor,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Animated filter bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterVisible ? 70 : 0,
            curve: Curves.easeInOut,
            child: _isFilterVisible
                ? Container(
                    color: kAppBackgroundColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: _categories
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _selectDateRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange ?? 'Select Date Range',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsContent(),
                _buildReportsContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Report Detail Page with PDF =====================
class ReportDetailPage extends StatelessWidget {
  final Report report;

  const ReportDetailPage({super.key, required this.report});

  // Generate PDF
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(report.title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Text("Category: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(report.category),
                pw.SizedBox(width: 20),
                pw.Text("Date: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    "${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}"),
              ],
            ),
            pw.Divider(height: 20, thickness: 1),
            pw.Text("Description:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(report.description),
            pw.SizedBox(height: 20),
            pw.Text("Generated by Admin Dashboard",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
      ),
    );

    // Open PDF preview or share
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(report.category,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}",
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  const Text(
                    "Description:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Generated by Admin Dashboard",
              style: TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- For Standalone Testing ----------------
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ReportPage(),
  ));
}
