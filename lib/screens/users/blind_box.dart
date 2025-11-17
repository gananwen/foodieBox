import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/screens/users/store_detail_page.dart';
import 'package:foodiebox/screens/users/cart_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import '../users/subpages/delivery_address_page.dart';
import 'package:foodiebox/models/promotion.dart';
import 'dart:async';
import 'package:foodiebox/models/product.dart'; 
import 'package:foodiebox/repositories/product_repository.dart'; 



class BlindBox extends StatefulWidget {
  const BlindBox({super.key});

  @override
  State<BlindBox> createState() => _BlindBoxState();
}

class _BlindBoxState extends State<BlindBox> {
  String? selectedAddressName;
  final TextEditingController _searchController = TextEditingController();
  
  final ProductRepository _productRepo = ProductRepository();

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  Map<String, List<String>> _vendorCategoriesCache = {};
  
  String? _selectedCategoryFilter; // Holds the currently selected filter label
  
  // --- FINAL FILTER ORDER & LABELS ---
  final Map<String, String> _categoryImages = {
    'Promo': 'assets/images/promo_deals.jpg', 
    'New': 'assets/images/new_stores.jpg', 
    'Top Rated': 'assets/images/top_rated.jpg', 
    'Halal': 'assets/images/halal.jpg', // NEW HALAL FILTER
  };
  // --- END FINAL FILTER ORDER ---


  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['selectedAddress'] != null) {
      final addr = data['selectedAddress'];
      setState(() => selectedAddressName =
          addr['address'] ?? '${addr['label']} - ${addr['contactName']}');
    }
  }

  Future<void> _openDeliveryToPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryAddressPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'selectedAddress': result,
        });

        setState(() {
          selectedAddressName =
              result['address'] ?? '${result['label']} - ${result['contactName']}';
        });
      }
    }
  }

  void _startAutoSlide(int totalPages) {
    if (_timer != null) {
      _timer!.cancel();
    }
    if (totalPages <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < totalPages - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // --- RESTORED CIRCULAR CATEGORY WIDGET (REDESIGNED & ALIGNED) ---
  Widget _buildCircleCategory(String label, String imagePath) {
    final isSelected = _selectedCategoryFilter == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle filter: If tapping current filter, clear it. Otherwise, set it.
          // Note: If 'All' is removed, selecting the already selected filter clears it.
          _selectedCategoryFilter = isSelected ? null : label;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // <-- FIX: Align contents to center
        children: [
          Container(
            width: 65, // Reduced size
            height: 65, // Reduced size
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // White background
              border: Border.all(
                color: isSelected ? kPrimaryActionColor : Colors.grey.shade300, // Light border
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: [
                // Subtle shadow for depth
                BoxShadow(
                    color: Colors.black.withOpacity(0.1), 
                    blurRadius: 4, 
                    offset: const Offset(0, 2))
              ],
              image: DecorationImage(
                  // Use AssetImage to load placeholder images
                  image: AssetImage(imagePath), 
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            fontSize: 12, 
            color: isSelected ? kPrimaryActionColor : kTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
  // --- END RESTORED CIRCULAR CATEGORY WIDGET ---
  
  // --- RESTORED: Helper to fetch one product for preview ---
  Future<Product?> _fetchProductPreview(String vendorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('products')
          .limit(1) // Just grab one product for the preview
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Product.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print("Error fetching product preview: $e");
      return null;
    }
  }

  // Helper function to build a single vendor card (UPDATED)
  Widget _buildCompactRestaurantCard(
    BuildContext context, 
    VendorModel vendor,
    List<PromotionModel> allPromotions,
  ) {
    int? bestDiscount;
    final vendorPromotions =
        allPromotions.where((p) => p.vendorId == vendor.uid).toList();
    if (vendorPromotions.isNotEmpty) {
      bestDiscount = vendorPromotions.fold(
          0,
          (max, promo) =>
              promo.discountPercentage > max! ? promo.discountPercentage : max);
      if (bestDiscount == 0) bestDiscount = null;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(vendor: vendor),
          ),
        );
      },
      child: Container(
        // Margin adjusted for categorized lists
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardColor, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: FutureBuilder<Product?>(
          future: _fetchProductPreview(vendor.uid),
          builder: (context, snapshot) {
            final productPreview = snapshot.data;
            
            // Mocked price calculation based on actual product if available
            final double discountedPrice = productPreview?.discountedPrice ?? (vendor.rating * 5.0) ?? 1.6;
            final double originalPrice = productPreview?.originalPrice ?? (discountedPrice + 3.0);
            final String deliveryTime = '${(vendor.reviewCount % 10) + 20} min';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Image on Left ---
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        vendor.businessPhotoUrl,
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 90,
                            width: 90,
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 90,
                            width: 90,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store,
                                size: 40, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    // --- "HOT DEALS" Tag ---
                    if (vendor.hasExpiryDeals)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'HOT DEAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // --- Details on Right ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name
                      Text(
                        vendor.storeName,
                        style: kLabelTextStyle.copyWith(fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Product Preview Title
                      if (productPreview != null)
                        Text(
                          productPreview.title,
                          style: kHintTextStyle.copyWith(fontSize: 14, color: kTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            vendor.rating.toStringAsFixed(1),
                            style: kLabelTextStyle.copyWith(fontSize: 14),
                          ),
                          Text(
                            ' (${vendor.reviewCount})・${deliveryTime}', // Use real review count & delivery time
                            style: kHintTextStyle.copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Discounted Price, Original Price, Delivery Time (Matching Image Style)
                      Row(
                        children: [
                          // Discounted Price (Large, Red/Amber)
                          Text(
                            'RM${discountedPrice.toStringAsFixed(2)}',
                            style: kLabelTextStyle.copyWith(
                                fontSize: 15, color: kPrimaryActionColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          // Original Price (Strikethrough)
                          Text(
                            'RM${originalPrice.toStringAsFixed(2)}',
                            style: kHintTextStyle.copyWith(
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          // Promotion Tag (Green Voucher Style)
                          if (bestDiscount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$bestDiscount% OFF', // <-- REAL DATA
                                style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- NEW: Function to cache product categories for a vendor ---
  Future<List<String>> _getVendorCategories(String vendorId) async {
    if (_vendorCategoriesCache.containsKey(vendorId)) {
      return _vendorCategoriesCache[vendorId]!;
    }
    
    try {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('products')
          .get();

      final categories = productSnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id).category)
          .where((category) => category.isNotEmpty)
          .toSet() // Get unique categories
          .toList();
      
      _vendorCategoriesCache[vendorId] = categories;
      return categories;
    } catch (e) {
      print("Error fetching categories for $vendorId: $e");
      return [];
    }
  }

  // --- MODIFIED: Widget to build the vendor list based on the filter state ---
  Widget _buildCategorizedVendorList(
      BuildContext context, List<VendorModel> vendors, List<PromotionModel> allPromotions) {
    
    final displayVendors = _getFilteredVendors(vendors, allPromotions); // Pass promotions list

    if (displayVendors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'No stores found for "${_selectedCategoryFilter ?? 'All'}".',
            style: kHintTextStyle,
          ),
        ),
      );
    }

    // Display the final list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 8.0),
          child: Text(
            _selectedCategoryFilter == null || _selectedCategoryFilter == 'All' ? 'All Blindbox Stores' : 'Stores for "${_selectedCategoryFilter}"',
            style: kLabelTextStyle.copyWith(fontSize: 18),
          ),
        ),
        ...displayVendors.map((vendor) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCompactRestaurantCard(context, vendor, allPromotions),
          );
        }).toList(),
      ],
    );
  }
  
  // --- NEW: Filter function using Promotion Data for Promo/New checks ---
  List<VendorModel> _getFilteredVendors(List<VendorModel> vendors, List<PromotionModel> allPromotions) {
    
    // Create a mutable copy for sorting
    List<VendorModel> mutableVendors = List<VendorModel>.from(vendors);

    // Default to show all if no filter is set or if 'All' was selected
    if (_selectedCategoryFilter == null) {
      return vendors; 
    }

    switch (_selectedCategoryFilter) {
      case 'Promo':
        // Filter: Show vendors that have at least one currently active promotion.
        final promoVendorIds = allPromotions.map((p) => p.vendorId).toSet();
        return vendors.where((v) => promoVendorIds.contains(v.uid)).toList();
        
      case 'Top Rated':
        // Sort: by rating (descending) and take the top 5
        mutableVendors.sort((a, b) => b.rating.compareTo(a.rating));
        return mutableVendors.take(5).toList();
        
      case 'New':
        // Sort: by UID (descending, mocking creation time/newest) and take the top 5
        mutableVendors.sort((a, b) => b.uid.compareTo(a.uid));
        return mutableVendors.take(5).toList();
        
      case 'Halal':
        // Filter: Show vendors where the halalCertificateUrl is NOT empty (meaning they have proof).
        return vendors.where((v) => v.halalCertificateUrl.isNotEmpty).toList();

      default:
        // If an explicit filter is active but doesn't match a defined case, return nothing or all
        return vendors;
    }
  }

  // --- START: RESTORED HELPER METHODS ---

  // --- Banner Widget with Border ---
  Widget _buildPromotionsBanner(
      BuildContext context, List<PromotionModel> allPromotions) {
    
    // Filter for Blindbox and bannerUrl
    final bannerPromotions = allPromotions
        .where((promo) =>
            promo.productType == 'Blindbox' &&
            promo.bannerUrl.isNotEmpty &&
            promo.vendorId.isNotEmpty)
        .toList();

    if (bannerPromotions.isEmpty) {
      // Return a container with the same gradient as the old one, but no text
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
          height: 112, // Same height as old banner
          width: double.infinity,
          decoration: BoxDecoration(
            // NOTE: Assuming kPromotionGradient is defined in styles.dart, using a solid color placeholder
            color: Colors.grey.shade300, 
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
           child: const Center(
             child: Text(
              'No promotions available', 
              style: TextStyle(color: Colors.black54)
            ),
           ),
        ),
      );
    }

    _startAutoSlide(bannerPromotions.length);

    return Container(
      height: 150, // Height for the banner
      margin: const EdgeInsets.only(top: 10, bottom: 10), // Added margin
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerPromotions.length,
        itemBuilder: (context, index) {
          final promo = bannerPromotions[index];
          // Use padding to create space between cards
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            // --- FIX: Add Border around the Card/Banner ---
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.0), // Light Border
              ),
              child: _buildPromotionCard(context, promo),
            ),
            // --- END FIX ---
          );
        },
        onPageChanged: (index) {
          _currentPage = index;
        },
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, PromotionModel promo) {
    return GestureDetector(
      onTap: () async {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(promo.vendorId) 
              .get();

          if (doc.exists) {
            final vendor = VendorModel.fromMap(doc.data() as Map<String, dynamic>);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreDetailPage(vendor: vendor),
              ),
            );
          }
        } catch (e) {
          print("Error navigating to vendor: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load store.')),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          promo.bannerUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kPrimaryActionColor)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.error, color: Colors.red),
            );
          },
        ),
      ),
    );
  }

  // --- END: RESTORED HELPER METHODS ---


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItemCount = cart.itemCount;
    final cartTotal = cart.subtotal;

    // --- Promotions Stream ---
    final allPromotionsStream = FirebaseFirestore.instance
        .collectionGroup('promotions')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            PromotionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
          ).toList()
        );

    return BasePage(
      currentIndex: 1,
      // --- Wrap with StreamBuilder for promotions ---
      child: StreamBuilder<List<PromotionModel>>(
        stream: allPromotionsStream,
        builder: (context, promotionSnapshot) {
          
          if (promotionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (promotionSnapshot.hasError) {
              print("Error loading promotions: ${promotionSnapshot.error}");
              String errorMsg = "Error loading promotions";
              if (promotionSnapshot.error.toString().contains('FAILED_PRECONDITION')) {
                errorMsg = "Firebase index required. Please create it.";
              }
              return Center(child: Text(errorMsg));
          }
          
          final now = DateTime.now();
          
          // --- FIX: Filter promotions by end date/start date/status ---
          final allPromotions = promotionSnapshot.data
              ?.where((p) => 
                  p.endDate.isAfter(now) &&
                  p.startDate.isBefore(now) &&
                  p.status == 'Active'
              ).toList() ?? [];

          // --- Get all Blindbox vendors ---
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vendors')
                .where('vendorType', isEqualTo: 'Blindbox')
                .snapshots(),
            builder: (context, vendorSnapshot) {
              if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
              }
              if (vendorSnapshot.hasError) {
                return Center(child: Text('Error: ${vendorSnapshot.error}'));
              }
              
              final vendors = vendorSnapshot.data!.docs
                  .map((doc) => VendorModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();
              
              return Stack(
                children: [
                  // --- Use CustomScrollView for scrolling ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80.0), // Space for cart
                    child: CustomScrollView(
                      slivers: [
                        SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 30),

                            // --- Deliver To Section ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _openDeliveryToPage, // Calls address selection
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Deliver to:',
                                              style: TextStyle(
                                                  fontSize: 14, color: Colors.black54)),
                                          Text(
                                            selectedAddressName ??
                                                'Choose delivery location',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: kTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // --- Search Bar ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search bundles or categories',
                                  prefixIcon:
                                      const Icon(Icons.search, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    // FIX: Correct parameter name from 'side' to 'borderSide'
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // --- Promotions Banner (with Border) ---
                            _buildPromotionsBanner(context, allPromotions),
                            
                            const SizedBox(height: 20),

                            // --- Horizontal Filter Buttons ---
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('Quick Filters', style: kLabelTextStyle),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 120, // Height for circular bubbles
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  // --- RESTORED CIRCULAR CATEGORIES ---
                                  ..._categoryImages.entries.map((entry) => 
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: _buildCircleCategory(entry.key, entry.value),
                                    ),
                                  ).toList(),
                                  // --- END RESTORED ---
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                          ]),
                        ),
                        
                        // --- VENDOR LIST (SliverList) ---
                        SliverList(
                          delegate: SliverChildListDelegate([
                            // This now builds the filtered vendor list
                            _buildCategorizedVendorList(context, vendors, allPromotions),
                            const SizedBox(height: 20), // Bottom padding
                          ]),
                        ),
                        // --- END VENDOR LIST ---
                      ],
                    ),
                  ),

                  // --- Floating Cart Bubble (REAL DATA) ---
                  Positioned(
                    right: 20,
                    bottom: 12,
                    child: AnimatedOpacity(
                      opacity: cartItemCount > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: cartItemCount > 0
                          ? Stack(
                              alignment: Alignment.topRight,
                              children: [
                                FloatingActionButton.extended(
                                  backgroundColor: Colors.amber,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const CartPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_cart,
                                      color: Colors.white),
                                  label: Text('RM ${cartTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white)),
                                ),
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
                                    child: Text('$cartItemCount',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  // --- END ---
                ],
              );
            }
          );
        }
      ),
    );
  }
}

class SliverToBoxBoxAdapter extends SliverToBoxAdapter {
  const SliverToBoxBoxAdapter({super.key, super.child});
}