import 'package:flutter/material.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/util/styles.dart';
import 'category_product_page.dart'; // N, required VendorModel vendorEW: navigate on category tap

// --- Category model (unchanged) ---
class GroceryCategory {
  final String name;
  final String imagePath;
  GroceryCategory({required this.name, required this.imagePath});
}

// --- Enum (unchanged) ---
enum DeliveryOption { delivery, pickup }

class StoreDetailPage extends StatefulWidget {
  final VendorModel vendor;

  const StoreDetailPage({super.key, required this.vendor});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  DeliveryOption _selectedOption = DeliveryOption.delivery;

  String _selectedDay = 'Today';
  String _selectedTime = 'No slots available';

  List<String> _availableTodaySlots = [];
  List<String> _availableTomorrowSlots = [];

  final List<int> _allPickupHours = [10, 11, 12, 13, 14, 15, 16];

  // --- Keep your category list and images as-is ---
  final List<GroceryCategory> _groceryCategories = [
    GroceryCategory(name: 'Frozen', imagePath: 'assets/images/frozen.png'),
    GroceryCategory(name: 'Baked Goods', imagePath: 'assets/images/bakery.png'),
    GroceryCategory(
        name: 'Vegetables', imagePath: 'assets/images/vegetables.png'),
    GroceryCategory(name: 'Spice', imagePath: 'assets/images/spice.png'),
    GroceryCategory(
        name: 'Beverages', imagePath: 'assets/images/beverages.png'),
    GroceryCategory(
        name: 'Non-Halal Food', imagePath: 'assets/images/non_halal.png'),
    GroceryCategory(name: 'View All', imagePath: 'assets/images/view_all.png'),
  ];

  // NOTE: We no longer need _selectedProductCategory for filtering inline.
  // It can be kept if you want to highlight selected UI later, but we won't use it for filtering.
  String? _selectedProductCategory;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    DateTime now = DateTime.now();
    int currentHour = now.hour;

    _availableTodaySlots = _allPickupHours
        .where((hour) => hour > currentHour)
        .map((hour) => _formatHour(hour))
        .toList();

    _availableTomorrowSlots =
        _allPickupHours.map((hour) => _formatHour(hour)).toList();

    if (_availableTodaySlots.isEmpty) {
      _selectedDay = 'Tomorrow';
      _selectedTime = _availableTomorrowSlots.isNotEmpty
          ? _availableTomorrowSlots.first
          : 'No slots available';
    } else {
      _selectedDay = 'Today';
      _selectedTime = _availableTodaySlots.first;
    }
  }

  String _formatHour(int hour) {
    String formatNum(int h) {
      if (h == 0) return '12:00 AM';
      if (h == 12) return '12:00 PM';
      if (h < 12) return '$h:00 AM';
      return '${h - 12}:00 PM';
    }

    return '${formatNum(hour)} – ${formatNum(hour + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // CHANGE: base to white
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildStoreHeader(),

          // --- Category grid (design preserved) ---
          if (widget.vendor.vendorType == 'Grocery')
            _buildCategoryGrid()
          else
            _buildSectionTitle('All Products'),

          // --- Title below grid stays "All Products" always ---
          _buildSectionTitle('All Products'),

          // --- Always show all products (no inline filtering anymore) ---
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: kYellowMedium,
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kTextColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          widget.vendor.businessPhotoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: kYellowLight,
              child: const Center(
                  child: CircularProgressIndicator(color: kPrimaryActionColor)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: kYellowLight,
              child: const Icon(Icons.store, size: 100, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vendor.storeName,
                  style: kLabelTextStyle.copyWith(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.vendor.storeAddress,
                    style: kHintTextStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(widget.vendor.rating.toStringAsFixed(1),
                        style: kLabelTextStyle.copyWith(fontSize: 15)),
                    const SizedBox(width: 4),
                    const Text("(100+)", style: kHintTextStyle),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        'Delivery',
                        Icons.delivery_dining,
                        _selectedOption == DeliveryOption.delivery,
                        () => setState(
                            () => _selectedOption = DeliveryOption.delivery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToggleButton(
                        'Pickup',
                        Icons.store,
                        _selectedOption == DeliveryOption.pickup,
                        () => setState(
                            () => _selectedOption = DeliveryOption.pickup),
                      ),
                    ),
                  ],
                ),
                if (_selectedOption == DeliveryOption.pickup)
                  _buildPickupTimeSelector(),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
        child: Text(title, style: kLabelTextStyle.copyWith(fontSize: 18)),
      ),
    );
  }

  // --- Category grid: same visuals, logic changes to navigate instead of filter ---
  Widget _buildCategoryGrid() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _groceryCategories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final category = _groceryCategories[index];

            // Preserve your selected highlight logic if desired
            final bool isSelected = (_selectedProductCategory == null &&
                    category.name == 'View All') ||
                (_selectedProductCategory == category.name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (category.name == 'View All') {
                    // View All should just show all categories; do not filter products
                    _selectedProductCategory = null;
                    // No navigation
                  } else {
                    _selectedProductCategory =
                        category.name; // if you want tile highlight
                    // Navigate to dedicated category products page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductPage(
                          vendor: widget.vendor,
                          categoryName: category.name,
                        ),
                      ),
                    );
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? kYellowMedium : kYellowLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      category.imagePath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.category,
                          size: 40,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: kHintTextStyle.copyWith(
                        fontSize: 12,
                        color: kTextColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPickupTimeSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: GestureDetector(
        onTap: () => _showTimeSlotModal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: kPrimaryActionColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Time',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: kTextColor)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedTime == 'No slots available'
                          ? 'No slots available'
                          : '$_selectedDay, $_selectedTime',
                      style: const TextStyle(color: kPrimaryActionColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
      String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kYellowMedium : kCardColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? kTextColor : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? kTextColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    // Always show all products for this vendor; no inline filtering
    final productQuery = FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendor.uid)
        .collection('products');

    return StreamBuilder<QuerySnapshot>(
      stream: productQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: kPrimaryActionColor),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Error: ${snapshot.error}', style: kHintTextStyle),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No products found for this shop.',
                    style: kHintTextStyle),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = snapshot.data!.docs[index];
              final product =
                  Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _buildProductCard(product);
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 3, offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child:
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: kLabelTextStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(product.description,
                    style: kHintTextStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'RM${product.discountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryActionColor),
                    ),
                    const SizedBox(width: 8),
                    if (product.originalPrice > product.discountedPrice)
                      Text(
                        'RM${product.originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: kPrimaryActionColor, size: 30),
        ],
      ),
    );
  }

  void _showTimeSlotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String localDay = _selectedDay;
        String localTime = _selectedTime;
        List<String> currentSlots = (localDay == 'Today')
            ? _availableTodaySlots
            : _availableTomorrowSlots;

        if (!currentSlots.contains(localTime) && currentSlots.isNotEmpty) {
          localTime = currentSlots.first;
        } else if (currentSlots.isEmpty) {
          localTime = 'No slots available';
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Pickup Time', style: kLabelTextStyle),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDayChip(
                            'Today',
                            localDay == 'Today',
                            setModalState,
                            _availableTodaySlots.isEmpty
                                ? null
                                : () {
                                    setModalState(() {
                                      localDay = 'Today';
                                      currentSlots = _availableTodaySlots;
                                      localTime = currentSlots.first;
                                    });
                                  },
                          ),
                          const SizedBox(width: 10),
                          _buildDayChip(
                            'Tomorrow',
                            localDay == 'Tomorrow',
                            setModalState,
                            () {
                              setModalState(() {
                                localDay = 'Tomorrow';
                                currentSlots = _availableTomorrowSlots;
                                if (!currentSlots.contains(localTime) &&
                                    currentSlots.isNotEmpty) {
                                  localTime = currentSlots.first;
                                } else if (currentSlots.isEmpty) {
                                  localTime = 'No slots available';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Available Slots', style: kHintTextStyle),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: currentSlots.isEmpty
                          ? const Center(
                              child: Text('No slots available for this day.',
                                  style: kHintTextStyle))
                          : ListView(
                              children: currentSlots.map((slot) {
                                final isSelected = localTime == slot;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(slot,
                                      style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                  leading: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? kYellowMedium
                                        : Colors.grey,
                                  ),
                                  onTap: () =>
                                      setModalState(() => localTime = slot),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: localTime == 'No slots available'
                          ? null
                          : () {
                              setState(() {
                                _selectedDay = localDay;
                                _selectedTime = localTime;
                              });
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kYellowMedium,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Center(
                          child: Text('Confirm',
                              style: TextStyle(color: kTextColor))),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayChip(String label, bool isSelected, StateSetter setModalState,
      VoidCallback? onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: isSelected
          ? kYellowMedium
          : (onTap == null ? Colors.grey.shade400 : Colors.grey[200]),
      labelStyle: TextStyle(
        color: isSelected
            ? kTextColor
            : (onTap == null ? Colors.grey.shade600 : Colors.black),
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
    );
  }
}
