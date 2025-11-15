import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'vendor_register_page.dart';
import 'admin_home_page.dart';

class VendorManagementPage extends StatefulWidget {
  const VendorManagementPage({super.key});

  @override
  State<VendorManagementPage> createState() => _VendorManagementPageState();
}

class _VendorManagementPageState extends State<VendorManagementPage> {
  bool _showFilter = false;
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
    return list.where((v) => v['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("Register Vendor",
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VendorRegisterPage()));
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchFilter(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFilterOptions(),
              crossFadeState: _showFilter
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
            Expanded(child: _buildVendorsTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AdminHomePage()));
              },
            ),
          ),
          const Center(
            child: Text(
              'Vendor Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search vendors",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune,
                color: _showFilter ? Colors.blue : Colors.black),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    final filters = ['All', 'Active', 'Suspended', 'Pending'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: filters.map((filter) {
            final selected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                onPressed: () => setState(() => _selectedFilter = filter),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      Size(80, 36), // 👈 Fixed width to prevent wrapping
                  backgroundColor: selected ? Colors.blue : Colors.white,
                  side: BorderSide(
                      color: selected ? Colors.blue : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  filter,
                  overflow: TextOverflow.ellipsis, // 👈 Prevents overflow
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVendorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No vendors found."));
        }

        final vendorList = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final joinedDate = (data['createdAt'] as Timestamp?)?.toDate();
          String status;
          if ((data['isLocked'] ?? false)) {
            status = 'Suspended';
          } else if (!(data['isApproved'] ?? false)) {
            status = 'Pending';
          } else {
            status = 'Active';
          }

          return {
            'docId': doc.id,
            'id': data['storePhone'] ?? 'N/A',
            'name': data['storeName'] ?? 'Unnamed Vendor',
            'status': status,
            'joined': joinedDate != null
                ? "${joinedDate.day}/${joinedDate.month}/${joinedDate.year}"
                : 'New',
            'raw': data,
          };
        }).toList();

        final searchTerm = _searchController.text.trim().toLowerCase();
        final searched = searchTerm.isEmpty
            ? vendorList
            : vendorList.where((v) {
                final name = (v['name'] as String).toLowerCase();
                final phone = (v['id'] as String).toLowerCase();
                return name.contains(searchTerm) || phone.contains(searchTerm);
              }).toList();

        final filtered = _filterList(searched);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final v = filtered[i];
            return _VendorCard(
              vendor: v,
              statusColor: _statusColor(v['status']),
              onView: () => _viewVendorDetails(
                  v['docId'], v['raw'] as Map<String, dynamic>),
              onEdit: () => _editVendorDialog(
                  v['docId'], v['raw'] as Map<String, dynamic>),
              onLock: () => _lockVendor(v['docId'], v['name']),
              onDelete: () =>
                  _confirmDeleteVendor(v['docId'], v['name'], 'Delete'),
              onApprove: v['status'] == 'Pending'
                  ? () => _approveVendor(v['docId'], v['name'])
                  : null,
              onDecline: v['status'] == 'Pending'
                  ? () => _confirmDeleteVendor(v['docId'], v['name'], 'Decline')
                  : null,
            );
          },
        );
      },
    );
  }

  // ================= Firestore actions =================
  Future<void> _approveVendor(String docId, String name) async {
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(docId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$name approved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _lockVendor(String docId, String name) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(docId)
          .get();
      final data = snapshot.data() as Map<String, dynamic>;
      final currentLocked = data['isLocked'] ?? false;
      await FirebaseFirestore.instance.collection('vendors').doc(docId).update({
        'isLocked': !currentLocked,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name ${!currentLocked ? "locked" : "unlocked"}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDeleteVendor(
      String docId, String name, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$action Vendor"),
        content: Text("Are you sure you want to $action $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$name $action completed')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ================= Edit Vendor =================
  Future<void> _editVendorDialog(String docId, Map<String, dynamic> raw) async {
    await showDialog(
      context: context,
      builder: (context) {
        final nameController =
            TextEditingController(text: raw['storeName'] ?? '');
        final phoneController =
            TextEditingController(text: raw['storePhone'] ?? '');
        final addressController =
            TextEditingController(text: raw['storeAddress'] ?? '');
        final vendorTypeController =
            TextEditingController(text: raw['vendorType'] ?? '');
        final licenseController =
            TextEditingController(text: raw['businessLicenseUrl'] ?? '');
        final photoController =
            TextEditingController(text: raw['businessPhotoUrl'] ?? '');
        final halalController =
            TextEditingController(text: raw['halalCertificateUrl'] ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Vendor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _inputField(nameController, 'Store Name'),
                    _inputField(phoneController, 'Store Phone (optional)'),
                    _inputField(addressController, 'Store Address (optional)'),
                    _inputField(vendorTypeController, 'Vendor Type (optional)'),
                    _inputField(
                        licenseController, 'Business License URL (optional)'),
                    _inputField(photoController, 'Store Photo URL (optional)'),
                    _inputField(
                        halalController, 'Halal Certificate URL (optional)'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      Map<String, dynamic> updated = {
                        'storeName': nameController.text.trim(),
                        'storePhone': phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        'storeAddress': addressController.text.trim().isEmpty
                            ? null
                            : addressController.text.trim(),
                        'vendorType': vendorTypeController.text.trim().isEmpty
                            ? null
                            : vendorTypeController.text.trim(),
                        'businessLicenseUrl':
                            licenseController.text.trim().isEmpty
                                ? null
                                : licenseController.text.trim(),
                        'businessPhotoUrl': photoController.text.trim().isEmpty
                            ? null
                            : photoController.text.trim(),
                        'halalCertificateUrl':
                            halalController.text.trim().isEmpty
                                ? null
                                : halalController.text.trim(),
                      };
                      await FirebaseFirestore.instance
                          .collection('vendors')
                          .doc(docId)
                          .update(updated);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vendor updated')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _inputField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  // ================= View Vendor =================
  Future<void> _viewVendorDetails(
      String docId, Map<String, dynamic> raw) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(raw['storeName'] ?? 'Vendor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.phone, 'Phone', raw['storePhone'] ?? 'N/A'),
              _detailRow(
                  Icons.location_on, 'Address', raw['storeAddress'] ?? 'N/A'),
              if ((raw['vendorType'] ?? '').toString().isNotEmpty)
                _detailRow(Icons.category, 'Type', raw['vendorType']),
              _detailRow(Icons.star, 'Rating', (raw['rating'] ?? 0).toString()),
              const SizedBox(height: 12),
              if (raw['businessLicenseUrl'] != null)
                _linkRow('Business License', raw['businessLicenseUrl']),
              if (raw['businessPhotoUrl'] != null)
                _linkRow('Store Photo', raw['businessPhotoUrl']),
              if (raw['halalCertificateUrl'] != null)
                _linkRow('Halal Certificate', raw['halalCertificateUrl']),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _linkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.link, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                url,
                style: const TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Vendor Card =================
class _VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final Color statusColor;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onLock;
  final VoidCallback onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

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
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Phone: ${vendor['id']}",
                        style: const TextStyle(fontSize: 12)),
                    Text("Joined: ${vendor['joined']}",
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(vendor['status'],
                    style: TextStyle(fontSize: 12, color: statusColor)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Approve")),
                ElevatedButton(
                    onPressed: onDecline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Decline")),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    onPressed: onView),
                IconButton(
                    icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
                IconButton(
                    icon: Icon(vendor['status'] == 'Suspended'
                        ? Icons.lock
                        : Icons.lock_open),
                    onPressed: onLock),
                IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete),
              ],
            ),
        ]),
      ),
    );
  }
}
