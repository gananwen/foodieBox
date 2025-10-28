import 'package:flutter/material.dart';
import '../../util/styles.dart'; // ensure your styles file defines kLabelTextStyle, kHintTextStyle, kPrimaryActionColor, kAppBackgroundColor, kTextColor
import 'admin_home_page.dart';

final List<Map<String, dynamic>> allPromotions = [
  {
    'vendor': 'Tasty Bites',
    'id': '0014',
    'status': 'Pending',
    'promo': '50% off on all burgers',
    'isNew': true,
    'actions': ['Decline', 'Approve'],
  },
  {
    'vendor': 'W Hotel buffet',
    'id': '0001',
    'status': 'Active',
    'promo': 'Free delivery on orders above RM20',
    'actions': ['View request'],
  },
  {
    'vendor': 'Verona Hills',
    'id': '0002',
    'status': 'Active',
    'promo': 'Buy 2 free 1',
    'actions': ['View request'],
  },
  {
    'vendor': 'Empire Sushi',
    'id': '0003',
    'status': 'Suspended',
    'promo': 'Free delivery on orders above RM15',
    'actions': ['View request'],
  },
];

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({Key? key}) : super(key: key);

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showFilter = false;
  String _selectedFilter = 'All';
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredAll = [];
  List<Map<String, dynamic>> filteredApprovals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_applyFilters);
    searchController.addListener(_applyFilters);

    // Initialize filtered lists
    filteredAll = List.from(allPromotions);
    filteredApprovals =
        allPromotions.where((p) => p['status'] == 'Pending').toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    String query = searchController.text.toLowerCase();

    // Filter for "All" tab
    filteredAll = allPromotions.where((promo) {
      bool matchesFilter =
          _selectedFilter == 'All' || promo['status'] == _selectedFilter;
      bool matchesQuery = promo['vendor'].toLowerCase().contains(query) ||
          promo['promo'].toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    // Filter for "Approvals" tab (Pending only)
    filteredApprovals = allPromotions.where((promo) {
      bool isPending = promo['status'] == 'Pending';
      bool matchesFilter =
          _selectedFilter == 'All' || promo['status'] == _selectedFilter;
      bool matchesQuery = promo['vendor'].toLowerCase().contains(query) ||
          promo['promo'].toLowerCase().contains(query);
      return isPending && matchesFilter && matchesQuery;
    }).toList();

    setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade600;
      case 'Active':
        return Colors.green.shade600;
      case 'Suspended':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  void _showPromotionDetails(Map<String, dynamic> promo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(promo['vendor'], style: kLabelTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vendor ID: ${promo['id']}", style: kHintTextStyle),
              const SizedBox(height: 8),
              Text("Promotion:", style: kHintTextStyle),
              Text(promo['promo'], style: kLabelTextStyle),
              const SizedBox(height: 8),
              Text("Status: ${promo['status']}",
                  style: TextStyle(color: _statusColor(promo['status']))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Close", style: TextStyle(color: Colors.black87)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promo) {
    final isPending = promo['status'] == 'Pending';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPromotionDetails(promo),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront_outlined,
                        color: Colors.black45),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(promo['vendor'], style: kLabelTextStyle),
                        Text("Vendor ID: ${promo['id']}",
                            style: kHintTextStyle),
                        Text(promo['promo'], style: kHintTextStyle),
                      ],
                    ),
                  ),
                  _buildStatusBadge(promo['status']),
                ],
              ),
              const Divider(height: 16),
              isPending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Approve",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Decline",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _showPromotionDetails(promo),
                          child: Row(
                            children: const [
                              Icon(Icons.remove_red_eye_outlined,
                                  color: Colors.black54, size: 20),
                              SizedBox(width: 4),
                              Text(
                                "View request",
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    final filters = ['All', 'Pending', 'Active', 'Suspended'];
    return Container(
      color: kAppBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = filter;
                    _applyFilters();
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? kPrimaryActionColor : Colors.transparent,
                  side: BorderSide(
                      color: selected
                          ? kPrimaryActionColor
                          : Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : kTextColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kAppBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHomePage(),
                ),
              );
            },
          ),
          title: const Text("Promotions",
              style: TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search + Filter Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search promotions",
                          hintStyle: kHintTextStyle,
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: Icon(Icons.tune,
                          color:
                              _showFilter ? kPrimaryActionColor : kTextColor),
                      onPressed: () =>
                          setState(() => _showFilter = !_showFilter)),
                ],
              ),
            ),
            // Filter Options
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFilterOptions(),
              crossFadeState: _showFilter
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: kPrimaryActionColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryActionColor,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Approvals'),
              ],
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAll.length,
                    itemBuilder: (context, i) =>
                        _buildPromotionCard(filteredAll[i]),
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApprovals.length,
                    itemBuilder: (context, i) =>
                        _buildPromotionCard(filteredApprovals[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PromotionsPage(),
  ));
}
