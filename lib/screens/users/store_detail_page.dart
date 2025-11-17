import 'package:flutter/material.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/util/styles.dart';
import 'product_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/cart_page.dart';
import 'package:foodiebox/enums/checkout_type.dart';

class GroceryCategory {
  final String name;
  final String imagePath;
  // CategoryName is the value used for Firestore query.
  final String categoryFilter; 
  GroceryCategory({required this.name, required this.imagePath, required this.categoryFilter});
}

class StoreDetailPage extends StatefulWidget {
  final VendorModel vendor;

  const StoreDetailPage({super.key, required this.vendor});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  // Local state for time modal
  String _selectedDay = 'Today';
  String _selectedTime = 'No slots available';

  List<String> _availableTodaySlots = [];
  List<String> _availableTomorrowSlots = [];

  final List<int> _allPickupHours = [10, 11, 12, 13, 14, 15, 16];

  // --- MODIFIED: Added categoryFilter property ---
  final List<GroceryCategory> _groceryCategories = [
    // Display Name, Image Path, Firestore Category Field Value
    GroceryCategory(name: 'Frozen', imagePath: 'assets/images/frozen.png', categoryFilter: 'Frozen'),
    GroceryCategory(name: 'Baked Goods', imagePath: 'assets/images/bakery.png', categoryFilter: 'Baked Goods'),
    GroceryCategory(
        name: 'Vegetables', imagePath: 'assets/images/vegetables.png', categoryFilter: 'Vegetables'),
    GroceryCategory(name: 'Spice', imagePath: 'assets/images/spice.png', categoryFilter: 'Spices'), // Assuming Firestore category is 'Spices'
    GroceryCategory(
        name: 'Beverages', imagePath: 'assets/images/beverages.png', categoryFilter: 'Beverages'),
    GroceryCategory(
        name: 'Non-Halal Food', imagePath: 'assets/images/non_halal.png', categoryFilter: 'Non-Halal Food'), // Uses the exact category name
    GroceryCategory(name: 'View All', imagePath: 'assets/images/view_all.png', categoryFilter: 'View All'),
  ];
  // --- END MODIFIED ---

  String? _selectedProductCategory;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    
    final cart = context.read<CartProvider>();
    _selectedDay = cart.selectedPickupDay ?? 'Today';
    _selectedTime = cart.selectedPickupTime ?? 
                    (_availableTodaySlots.isNotEmpty 
                        ? _availableTodaySlots.first 
                        : 'No slots available');
    if (_selectedDay == 'Today' && !_availableTodaySlots.contains(_selectedTime)) {
      _selectedTime = _availableTodaySlots.isNotEmpty 
                      ? _availableTodaySlots.first 
                      : 'No slots available';
    }
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

    final cart = context.read<CartProvider>();
    if (cart.selectedPickupTime == null || cart.selectedPickupTime == 'No slots available') {
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
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildStoreHeader(cart),
          if (widget.vendor.vendorType == 'Grocery')
            _buildCategoryGrid()
          else
            _buildSectionTitle('All Products'),
          _buildProductList(),
        ],
      ),
      floatingActionButton: _buildFloatingCartButton(context),
    );
  }

  // --- MODIFIED: Implemented the exact requested FloatingActionButton.extended design ---
  Widget _buildFloatingCartButton(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final itemCount = cart.itemCount;
    // Using subtotal, as confirmed in the previous step
    final cartTotal = cart.subtotal; 

    return AnimatedOpacity(
      opacity: itemCount > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: itemCount > 0
          ? Stack(
              clipBehavior: Clip.none, // Essential for badge visibility
              alignment: Alignment.topRight, 
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  backgroundColor: Colors.amber, 
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: Text('RM ${cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white)),
                ),
                // Custom item count badge positioned as requested (right: 0, top: 0)
                Positioned(
                  right: 0, 
                  top: 0,   
                  child: Container(
                    padding: const EdgeInsets.all(6), 
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        // Not explicitly bolded, matching the requested snippet style
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
  // --- END MODIFIED ---

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

  Widget _buildStoreHeader(CartProvider cart) {
    final selectedOption = cart.selectedCheckoutType;
    final bool canPickup = cart.itemCount == 0 ||
        (cart.items.isNotEmpty && cart.itemsList.first.vendorId == widget.vendor.uid);

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
                    // --- ( ✨ FIXED: Replaced placeholder with real reviewCount ✨ ) ---
                    Text("(${widget.vendor.reviewCount})", style: kHintTextStyle),
                    // --- ( ✨ END FIX ✨ ) ---
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        'Delivery',
                        Icons.delivery_dining,
                        selectedOption == CheckoutType.delivery,
                        () => context
                            .read<CartProvider>()
                            .setCheckoutOption(CheckoutType.delivery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToggleButton(
                        'Pickup',
                        Icons.store,
                        selectedOption == CheckoutType.pickup,
                        canPickup
                            ? () => context.read<CartProvider>().setCheckoutOption(
                                  CheckoutType.pickup,
                                  day: _selectedDay,
                                  time: _selectedTime,
                                )
                            : null,
                      ),
                    ),
                  ],
                ),
                if (!canPickup && cart.itemCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Pickup is only available for one store at a time. Your cart contains items from another store.',
                      textAlign: TextAlign.center,
                      style: kHintTextStyle.copyWith(color: Colors.red, fontSize: 12),
                    ),
                  ),
                
                if (selectedOption == CheckoutType.pickup)
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
            // Uses the categoryFilter for selection state comparison
            final bool isSelected = (_selectedProductCategory == null &&
                    category.categoryFilter == 'View All') ||
                (_selectedProductCategory == category.categoryFilter);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (category.categoryFilter == 'View All') {
                    // Selecting 'View All' clears the category filter
                    _selectedProductCategory = null;
                  } else {
                    // Selecting a specific category sets the filter to its categoryFilter value
                    _selectedProductCategory = category.categoryFilter;
                    // Note: This category selection *only* filters the local product list
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
                      category.name, // Displays the readable name (e.g., "Non-Halal Food")
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
      String text, IconData icon, bool isSelected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kYellowMedium
              : (onTap == null ? Colors.grey.shade200 : kCardColor),
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
            Icon(icon,
                color: isSelected
                    ? kTextColor
                    : (onTap == null
                        ? Colors.grey.shade400
                        : Colors.grey.shade600)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? kTextColor
                    : (onTap == null
                        ? Colors.grey.shade400
                        : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    // 1. Start with the base query for the vendor's products
    Query<Map<String, dynamic>> productQuery = FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendor.uid)
        .collection('products');

    // 2. Add filtering if a category is selected
    if (_selectedProductCategory != null) {
      productQuery =
          productQuery.where('category', isEqualTo: _selectedProductCategory);
    }

    // Since we can't get a Stream<Query<Product>> from the result of a where clause,
    // we use a generic StreamBuilder and map the documents manually.
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
          final message = _selectedProductCategory == null
              ? 'No products found for this shop.'
              : 'No products found in the "${_selectedProductCategory!}" category.';
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(message, style: kHintTextStyle),
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
              
              // We pass context to read the cart provider
              return _buildProductCard(context, product);
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  // --- ( ✨ MODIFICATION: Added context and cart checks ✨ ) ---
  Widget _buildProductCard(BuildContext context, Product product) {
    // Get the cart provider to check item quantities
    final cart = context.watch<CartProvider>();

    // Check stock levels
    final bool isOutOfStock = product.quantity <= 0;
    final int cartQuantity = cart.getQuantityInCart(product.id!);
    final bool canAddMore = (cartQuantity + 1) <= product.quantity;

    return Opacity(
      opacity: isOutOfStock ? 0.5 : 1.0, // Make item transparent if out of stock
      child: InkWell(
        onTap: isOutOfStock
            ? null // Disable tap if out of stock
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
                      product: product,
                      vendor: widget.vendor,
                    ),
                  ),
                );
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Stack(
            children: [
              Row(
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
                        // --- ( ✨ NEW: Show Stock ✨ ) ---
                        const SizedBox(height: 4),
                        Text(
                          isOutOfStock
                              ? 'Out of Stock'
                              : 'Stock: ${product.quantity}',
                          style: kHintTextStyle.copyWith(
                            fontSize: 13,
                            color: product.quantity < 5 && !isOutOfStock
                                ? Colors.red
                                : Colors.grey,
                            fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // --- ( ✨ END NEW ✨ ) ---
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: isOutOfStock ? Colors.grey : kPrimaryActionColor, // Disable color
                        size: 30),
                    onPressed: isOutOfStock
                        ? null // Disable button if out of stock
                        : () {
                            // Read cart provider for action
                            final cart = context.read<CartProvider>();
                            
                            // 1. Check if user is mixing stores
                            final bool canAdd = cart.itemCount == 0 ||
                                (cart.items.isNotEmpty && cart.itemsList.first.vendorId == widget.vendor.uid);
                            
                            if (!canAdd) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('You can only order from one store at a time.'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            // 2. Check if stock is available
                            if (!canAddMore) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'No more stock available for ${product.title}. You have $cartQuantity in cart.'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            // 3. Add item
                            cart.addItem(product, widget.vendor, 1);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.title} added to cart!'),
                                backgroundColor: kPrimaryActionColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                  ),
                ],
              ),
              // --- ( ✨ NEW: Out of Stock Overlay ✨ ) ---
              if (isOutOfStock)
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.5), // Semi-transparent overlay
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: const EdgeInsets.only(left: 80), // Align with text
                      child: const Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              // --- ( ✨ END NEW ✨ ) ---
            ],
          ),
        ),
      ),
    );
  }
  // --- ( ✨ END MODIFICATION ✨ ) ---

  void _showTimeSlotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final cart = modalContext.read<CartProvider>();
        
        String localDay = cart.selectedPickupDay ?? _selectedDay;
        String localTime = cart.selectedPickupTime ?? _selectedTime;
        
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
                              cart.setCheckoutOption(
                                CheckoutType.pickup,
                                day: localDay,
                                time: localTime,
                              );
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