// promotions_admin_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'voucher_form_screen.dart'; // keep form separate

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

  List<Map<String, dynamic>> _allVouchers = [];
  List<Map<String, dynamic>> _filteredVouchers = [];

  static const double _cardRadius = 12.0;
  static const Color _bgColor = Color(0xFFF6F7FB);
  static const Color _primary = Color(0xFF1565C0);
  static const double _cardElevation = 6.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchAllVouchers();
      } else {
        _applyFilters();
      }
      setState(() {});
    });
    _searchController.addListener(() {
      if (_tabController.index == 0) {
        _applyFilters();
      } else {
        _applyVoucherFilters();
      }
    });
    _fetchAllPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ------------------- FETCH PROMOTIONS -------------------
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
            'vendorId': vendorDoc.id,
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
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ------------------- FETCH VOUCHERS -------------------
  Future<void> _fetchAllVouchers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('vouchers').get();

      final vouchers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'code': data['code'] ?? '',
          'description': data['description'] ?? '',
          'discountType': data['discountType'] ?? '',
          'discountValue': data['discountValue'] ?? 0,
          'minSpend': data['minSpend'] ?? 0,
          'applicableOrderType': data['applicableOrderType'] ?? '',
          'firstTimeOnly': data['firstTimeOnly'] ?? false,
          'weekendOnly': data['weekendOnly'] ?? false,
          'startDate': data['startDate'],
          'endDate': data['endDate'],
          'active': data['active'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();

      setState(() {
        _allVouchers = vouchers;
        _filteredVouchers = List.from(vouchers);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ------------------- FILTERS -------------------
  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();

    _filteredAll = _allPromotions.where((p) {
      final matchesSearch = p['vendor'].toString().toLowerCase().contains(q) ||
          p['title'].toString().toLowerCase().contains(q) ||
          p['productType'].toString().toLowerCase().contains(q);

      final matchesStatus =
          _selectedFilter == 'All' || p['status'] == _selectedFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    setState(() {});
  }

  void _applyVoucherFilters() {
    final q = _searchController.text.trim().toLowerCase();
    _filteredVouchers = _allVouchers.where((v) {
      return v['name'].toLowerCase().contains(q) ||
          v['code'].toLowerCase().contains(q) ||
          v['description'].toLowerCase().contains(q);
    }).toList();
    setState(() {});
  }

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

  // ------------------- UPDATE / DELETE -------------------
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

  Future<void> _deleteVoucher(String id) async {
    final ok = await _confirmDialog('Delete', 'Delete this voucher?');
    if (ok == true) {
      await FirebaseFirestore.instance.collection('vouchers').doc(id).delete();
      _fetchAllVouchers();
    }
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
      ),
    );
  }

  // ------------------- TOP RIGHT ICON -------------------
  Widget _buildTopRightIcon() {
    if (_tabController.index == 0) {
      // Promotions
      return IconButton(
        icon: Icon(Icons.tune, color: _showFilter ? _primary : Colors.black87),
        onPressed: () => setState(() => _showFilter = !_showFilter),
      );
    } else {
      // Voucher
      return IconButton(
        icon: const Icon(Icons.add, color: Colors.black87),
        onPressed: () async {
          // Open voucher form screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoucherFormScreen(
                onSaved: _fetchAllVouchers,
              ),
            ),
          );
        },
      );
    }
  }

  // ------------------- MAIN UI -------------------
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
        actions: [_buildTopRightIcon()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_tabController.index == 0)
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
                Tab(text: "Promotions"),
                Tab(text: "Voucher"),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text("Error: $_error"))
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (_tabController.index == 0) {
                              await _fetchAllPromotions();
                            } else {
                              await _fetchAllVouchers();
                            }
                          },
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildGridView(_filteredAll),
                              _buildVoucherGridView(_filteredVouchers),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- SEARCH BAR -------------------
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
                    hintText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.search, color: Colors.grey),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- FILTER CHIPS -------------------
  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Active', 'Declined'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 40,
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

  // ------------------- PROMOTIONS GRID -------------------
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

  // ------------------- VOUCHERS GRID -------------------
  Widget _buildVoucherGridView(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 40),
          Center(
              child: Text('No vouchers found',
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
      itemBuilder: (context, i) => _buildVoucherCard(items[i]),
    );
  }

  // ------------------- PROMO CARD -------------------
  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final banner = promo['bannerURL'];
    final status = promo['status'];

    return Material(
      elevation: _cardElevation,
      borderRadius: BorderRadius.circular(_cardRadius),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: () {},
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
                    const Spacer(),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- VOUCHER CARD -------------------
  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    return Material(
      elevation: _cardElevation,
      borderRadius: BorderRadius.circular(_cardRadius),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoucherFormScreen(
                voucher: voucher,
                onSaved: _fetchAllVouchers,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(voucher['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(voucher['code'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 6),
              Text(voucher['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _smallButton(
                      text: 'Edit',
                      color: Colors.blue.shade700,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoucherFormScreen(
                              voucher: voucher,
                              onSaved: _fetchAllVouchers,
                            ),
                          ),
                        );
                      }),
                  const SizedBox(width: 8),
                  _smallButton(
                      text: 'Delete',
                      color: Colors.red.shade700,
                      onTap: () => _deleteVoucher(voucher['id'])),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- SMALL BUTTON -------------------
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

  // ------------------- PROMOTION DETAILS DIALOG -------------------
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
                    Text(
                      promo['title'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
