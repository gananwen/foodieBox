import 'package:flutter/material.dart';
import 'vendor_register_page.dart';
import 'admin_home_page.dart';

class VendorManagementPage extends StatefulWidget {
  const VendorManagementPage({super.key});

  @override
  State<VendorManagementPage> createState() => _VendorManagementPageState();
}

class _VendorManagementPageState extends State<VendorManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFilter = false;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> vendors = [
    {'name': 'Tasty Bites', 'id': '0014', 'status': 'Pending', 'joined': 'New'},
    {
      'name': 'W Hotel Buffet',
      'id': '0001',
      'status': 'Active',
      'joined': '12/04/2024'
    },
    {
      'name': 'Verona Hills',
      'id': '0002',
      'status': 'Active',
      'joined': '12/05/2023'
    },
    {
      'name': 'Empire Sushi',
      'id': '0003',
      'status': 'Suspended',
      'joined': '04/08/2024'
    },
  ];

  final List<Map<String, dynamic>> customers = [
    {
      'name': 'Sophie Hart',
      'id': 'CUS-0234',
      'joined': '10/04/2024',
      'status': 'Active'
    },
    {
      'name': 'Afsar Hossen',
      'id': 'CUS-0761',
      'joined': '12/03/2023',
      'status': 'Active'
    },
    {
      'name': 'Dave David',
      'id': 'CUS-0451',
      'joined': '19/04/2022',
      'status': 'Suspended'
    },
    {
      'name': 'Emily Chen',
      'id': 'CUS-0802',
      'joined': '01/01/2024',
      'status': 'Active'
    },
  ];

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

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green.shade700;
      case 'Pending':
        return Colors.orange.shade700;
      case 'Suspended':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'New') {
      return list.where((e) => e['joined'] == 'New').toList();
    }
    return list.where((e) => e['status'] == _selectedFilter).toList();
  }

  void _showPopupDialog({
    required String title,
    required Widget content,
    bool requireConfirm = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title,
            style: const TextStyle(
                color: kTextColor, fontWeight: FontWeight.bold)),
        content: content,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: kTextColor))),
          if (requireConfirm)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryActionColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$title confirmed')));
              },
              child: const Text('Confirm'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryActionColor,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          "Register Vendor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VendorRegisterPage()),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Top Bar
            Container(
              color: kCardColor,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: kTextColor),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminHomePage()),
                        );
                      },
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Vendor Management &\nCustomer Support',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Search + Filter
            Container(
              color: kCardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search vendors or customers",
                          hintStyle:
                              TextStyle(fontSize: 14, color: Colors.black54),
                          prefixIcon:
                              Icon(Icons.search, size: 20, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: _showFilter ? kPrimaryActionColor : kTextColor,
                    ),
                    onPressed: () => setState(() => _showFilter = !_showFilter),
                  ),
                ],
              ),
            ),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFilterOptions(),
              crossFadeState: _showFilter
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),

            // 🔹 Tabs
            Container(
              color: kCardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: kPrimaryActionColor,
                unselectedLabelColor: Colors.black54,
                indicatorColor: kPrimaryActionColor,
                tabs: const [
                  Tab(text: 'Vendors'),
                  Tab(text: 'Customers'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVendorsTab(),
                  _buildCustomersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    final filters = ['All', 'Active', 'Suspended', 'New'];
    return Container(
      color: kCardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                onPressed: () => setState(() => _selectedFilter = filter),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? kPrimaryActionColor : Colors.white,
                  side: BorderSide(
                      color: selected
                          ? kPrimaryActionColor
                          : Colors.grey.shade300),
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

  Widget _buildVendorsTab() {
    final filtered = _filterList(vendors);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final v = filtered[i];
        return _VendorCard(
          vendor: v,
          statusColor: _statusColor(v['status']),
          onView: () => _showPopupDialog(
            title: "Vendor Details",
            content: Text("Full details of ${v['name']} here."),
          ),
          onEdit: () => _showPopupDialog(
            title: "Edit Vendor",
            requireConfirm: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: InputDecoration(
                        labelText: 'Vendor Name', hintText: v['name'])),
                TextField(
                    decoration: InputDecoration(
                        labelText: 'Vendor ID', hintText: v['id'])),
              ],
            ),
          ),
          onLock: () => _showPopupDialog(
            title: "Lock Vendor",
            content: Text("Lock ${v['name']}?"),
            requireConfirm: true,
          ),
          onDelete: () => _showPopupDialog(
            title: "Delete Vendor",
            content: Text("Delete ${v['name']}?"),
            requireConfirm: true,
          ),
          onApprove: () => _showPopupDialog(
            title: "Approve Vendor",
            content: Text("Approve ${v['name']}?"),
            requireConfirm: true,
          ),
          onDecline: () => _showPopupDialog(
            title: "Decline Vendor",
            content: Text("Decline ${v['name']}?"),
            requireConfirm: true,
          ),
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    final filtered = _filterList(customers);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final c = filtered[i];
        return _CustomerCard(
          customer: c,
          statusColor: _statusColor(c['status']),
          onView: () => _showPopupDialog(
            title: "Customer Details",
            content: Text("Viewing details of ${c['name']}"),
          ),
          onLock: () => _showPopupDialog(
            title: "Lock Customer",
            content: Text("Lock ${c['name']}?"),
            requireConfirm: true,
          ),
          onRefresh: () => _showPopupDialog(
            title: "Reset Account",
            content: Text("Reset ${c['name']}?"),
            requireConfirm: true,
          ),
        );
      },
    );
  }
}

class _VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final Color statusColor;
  final VoidCallback onView, onEdit, onLock, onDelete;
  final VoidCallback? onApprove, onDecline;

  const _VendorCard({
    required this.vendor,
    required this.statusColor,
    required this.onView,
    required this.onEdit,
    required this.onLock,
    required this.onDelete,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = vendor['status'] == 'Pending';
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storefront_outlined,
                    color: Colors.black45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: kTextColor)),
                      Text("Vendor ID: ${vendor['id']}",
                          style: const TextStyle(fontSize: 12)),
                      Text("Joined: ${vendor['joined']}",
                          style: const TextStyle(fontSize: 12)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(vendor['status'],
                    style: TextStyle(fontSize: 11, color: statusColor)),
              ),
            ],
          ),
          const Divider(height: 16),
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryActionColor),
                    child: const Text("Approve",
                        style: TextStyle(color: Colors.white))),
                ElevatedButton(
                    onPressed: onDecline,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87),
                    child: const Text("Decline",
                        style: TextStyle(color: Colors.white))),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        color: kTextColor),
                    onPressed: onView),
                IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kTextColor),
                    onPressed: onEdit),
                IconButton(
                    icon: const Icon(Icons.lock_outline, color: kTextColor),
                    onPressed: onLock),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: kTextColor),
                    onPressed: onDelete),
              ],
            ),
        ]),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Color statusColor;
  final VoidCallback onView, onLock, onRefresh;

  const _CustomerCard({
    required this.customer,
    required this.statusColor,
    required this.onView,
    required this.onLock,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person_outline,
                    color: Colors.black45, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: kTextColor)),
                      Text("Customer ID: ${customer['id']}",
                          style: const TextStyle(fontSize: 12)),
                      Text("Joined: ${customer['joined']}",
                          style: const TextStyle(fontSize: 12)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(customer['status'],
                    style: TextStyle(fontSize: 11, color: statusColor)),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined,
                      color: kTextColor),
                  onPressed: onView),
              IconButton(
                  icon: const Icon(Icons.refresh, color: kTextColor),
                  onPressed: onRefresh),
              IconButton(
                  icon: const Icon(Icons.lock_outline, color: kTextColor),
                  onPressed: onLock),
            ],
          ),
        ]),
      ),
    );
  }
}
