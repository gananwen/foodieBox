// promotions_admin_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PromotionsAdminPage extends StatefulWidget {
  const PromotionsAdminPage({Key? key}) : super(key: key);

  @override
  State<PromotionsAdminPage> createState() => _PromotionsAdminPageState();
}

class _PromotionsAdminPageState extends State<PromotionsAdminPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _showFilter = false;
  String _selectedFilter = 'All';
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _allPromotions = [];
  List<Map<String, dynamic>> _filteredAll = [];
  List<Map<String, dynamic>> _filteredApprovals = [];

  static const double _cardRadius = 12.0;
  static const Color _bgColor = Color(0xFFF6F7FB);
  static const Color _primary = Color(0xFF1565C0);
  static const double _cardElevation = 6.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_applyFilters);
    _searchController.addListener(_applyFilters);
    _fetchAllPromotions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_applyFilters);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FETCH ALL PROMOTIONS (FIXED VERSION)
  // ---------------------------------------------------------------------------
  Future<void> _fetchAllPromotions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendors').get();

      final List<Map<String, dynamic>> promotions = [];

      for (final vendorDoc in vendorsSnapshot.docs) {
        final vendorData = vendorDoc.data();

        final vendorName =
            vendorData['storeName']?.toString().trim().isNotEmpty == true
                ? vendorData['storeName']
                : vendorData['name']?.toString().trim().isNotEmpty == true
                    ? vendorData['name']
                    : vendorDoc.id;

        final promoSnapshot =
            await vendorDoc.reference.collection('promotions').get();

        if (promoSnapshot.docs.isEmpty) continue;

        for (final promoDoc in promoSnapshot.docs) {
          final raw = Map<String, dynamic>.from(promoDoc.data());

          promotions.add({
            'vendor': vendorName,
            'vendorId': vendorDoc.id, // correct vendor UID
            'id': promoDoc.id,
            'title': raw['title'] ?? raw['promotionTitle'] ?? '',
            'bannerURL': raw['bannerURL'] ?? raw['bannerUrl'],
            'claimedRedemptions': raw['claimedRedemptions'] ?? 0,
            'totalRedemptions': raw['totalRedemptions'] ?? 0,
            'discountPercentage':
                raw['discountPercentage'] ?? raw['discount'] ?? 0,
            'productType': raw['productType'] ?? '',
            'startDate': raw['startDate'],
            'endDate': raw['endDate'],
            'status': raw['status'] ?? 'Pending',
          });
        }
      }

      setState(() {
        _allPromotions = promotions;
        _filteredAll = List.from(promotions);
        _filteredApprovals =
            promotions.where((p) => p['status'] == 'Pending').toList();
        _loading = false;
      });
    } catch (e, st) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      debugPrint("Error: $e\n$st");
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER + SEARCH (FIXED VERSION)
  // ---------------------------------------------------------------------------
  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();

    bool matchesSearch(Map<String, dynamic> p) {
      return p['vendor'].toString().toLowerCase().contains(q) ||
          p['title'].toString().toLowerCase().contains(q) ||
          p['productType'].toString().toLowerCase().contains(q);
    }

    bool matchesStatus(Map<String, dynamic> p) {
      return _selectedFilter == 'All' || p['status'] == _selectedFilter;
    }

    _filteredAll = _allPromotions
        .where(
          (p) => matchesStatus(p) && matchesSearch(p),
        )
        .toList();

    _filteredApprovals = _allPromotions
        .where((p) => p['status'] == 'Pending' && matchesSearch(p))
        .toList();

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // STATUS COLOR
  // ---------------------------------------------------------------------------
  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'Active':
        return Colors.green.shade700;
      case 'Suspended':
        return Colors.red.shade700;
      case 'Declined':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE STATUS / DELETE
  // ---------------------------------------------------------------------------
  Future<void> _updateStatus(
      {required String vendorId,
      required String promoId,
      required String status}) async {
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('promotions')
          .doc(promoId)
          .update({'status': status});

      _fetchAllPromotions();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Promotion $status')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deletePromotion(
      {required String vendorId, required String promoId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('promotions')
          .doc(promoId)
          .delete();

      _fetchAllPromotions();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Promotion deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------
  String _formatDate(dynamic ts) {
    if (ts == null) return "N/A";
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
    }
    try {
      final dt = DateTime.parse(ts.toString());
      return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
    } catch (_) {
      return ts.toString();
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  void _showPromotionDetails(Map<String, dynamic> promo) {
    showDialog(
      context: context,
      builder: (context) {
        final banner = promo['bannerURL'];
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo['title'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                _statusColor(promo['status']).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promo['status'],
                            style: TextStyle(
                                color: _statusColor(promo['status']),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (banner != null && banner.toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(banner, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _detailRow("Vendor", promo['vendor']),
                    _detailRow("Discount", "${promo['discountPercentage']}%"),
                    _detailRow("Product Type", promo['productType']),
                    _detailRow("Start", _formatDate(promo['startDate'])),
                    _detailRow("End", _formatDate(promo['endDate'])),
                    _detailRow(
                        "Total Redemptions", "${promo['totalRedemptions']}"),
                    _detailRow("Claimed", "${promo['claimedRedemptions']}"),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                        const SizedBox(width: 8),
                        // Only show buttons for Pending promotions
                        if (promo['status'] == 'Pending') ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _updateStatus(
                                  vendorId: promo['vendorId'],
                                  promoId: promo['id'],
                                  status: "Active");
                            },
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _updateStatus(
                                  vendorId: promo['vendorId'],
                                  promoId: promo['id'],
                                  status: "Declined");
                            },
                            child: const Text("Decline"),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text("$label:",
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog(String title, String message) {
    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Confirm")),
              ],
            ));
  }

  // ---------------------------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Promotions",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFilterChips(),
              crossFadeState: _showFilter
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
            TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _primary,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Approvals"),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text("Error: $_error"))
                      : RefreshIndicator(
                          onRefresh: _fetchAllPromotions,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildGridView(_filteredAll),
                              _buildGridView(_filteredApprovals),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    hintText: 'Search promotions',
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.search, color: Colors.grey),
                    )),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.tune,
                color: _showFilter ? _primary : Colors.black87),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Active', 'Declined'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 40, // 👈 fixes chip height
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = filters[i];
            final selected = _selectedFilter == f;
            return ChoiceChip(
              label: Text(
                f,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              selected: selected,
              selectedColor: _primary,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = f;
                  _applyFilters();
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 40),
          Center(
              child: Text('No promotions found',
                  style: TextStyle(color: Colors.black54))),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildPromoCard(items[i]),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final banner = promo['bannerURL'];
    final status = promo['status'];

    return Material(
      elevation: _cardElevation,
      borderRadius: BorderRadius.circular(_cardRadius),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: () => _showPromotionDetails(promo),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_cardRadius),
                topRight: Radius.circular(_cardRadius),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: banner != null && banner.toString().isNotEmpty
                    ? Image.network(
                        banner,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                            child: Icon(Icons.photo,
                                size: 40, color: Colors.black26)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo['vendor'] ?? 'Unknown Vendor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${promo['discountPercentage']}%",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(), // 👈 Push buttons to bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'Pending') ...[
                          _smallButton(
                            text: "Approve",
                            color: Colors.green.shade700,
                            onTap: () async {
                              final ok = await _confirmDialog(
                                  "Approve", "Approve this?");
                              if (ok == true) {
                                await _updateStatus(
                                  vendorId: promo['vendorId'],
                                  promoId: promo['id'],
                                  status: 'Active',
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _smallButton(
                            text: "Decline",
                            color: Colors.red.shade700,
                            onTap: () async {
                              final ok = await _confirmDialog(
                                  "Decline", "Decline this?");
                              if (ok == true) {
                                await _updateStatus(
                                  vendorId: promo['vendorId'],
                                  promoId: promo['id'],
                                  status: 'Declined',
                                );
                              }
                            },
                          ),
                        ] else ...[
                          _smallButton(
                            text: "View",
                            color: Colors.blueGrey.shade700,
                            onTap: () => _showPromotionDetails(promo),
                          ),
                          const SizedBox(width: 8),
                          _smallButton(
                            text: "Delete",
                            color: Colors.red.shade700,
                            onTap: () async {
                              final ok = await _confirmDialog(
                                  "Delete", "Delete this?");
                              if (ok == true) {
                                await _deletePromotion(
                                  vendorId: promo['vendorId'],
                                  promoId: promo['id'],
                                );
                              }
                            },
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            )),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FULLSCREEN IMAGE VIEW
// ---------------------------------------------------------------------------
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImagePage({required this.imageUrl, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
