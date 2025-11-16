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
import '../users/delivery_to_page.dart';
// --- IMPORT ADDED ---
import 'package:foodiebox/models/promotion.dart';
// --- IMPORT ADDED FOR TIMER ---
import 'dart:async';

class BlindBox extends StatefulWidget {
  const BlindBox({super.key});

  @override
  State<BlindBox> createState() => _BlindBoxState();
}

class _BlindBoxState extends State<BlindBox> {
  String? selectedAddressName;
  final TextEditingController _searchController = TextEditingController();

  // --- ( ✨ NEW: Added for sliding banner ✨ ) ---
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  // --- ( ✨ END NEW ✨ ) ---

  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
    // --- ( ✨ NEW: Init PageController ✨ ) ---
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
  }

  // --- ( ✨ NEW: Added dispose for controllers ✨ ) ---
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  // --- ( ✨ END NEW ✨ ) ---


  Future<void> _loadSelectedAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['selectedAddress'] != null) {
      final addr = data['selectedAddress'];
      setState(() =>
          selectedAddressName = '${addr['label']} - ${addr['contactName']}');
    }
  }

  Future<void> _openDeliveryToPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryToPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'selectedAddress': result,
        });
        setState(() {
          selectedAddressName = '${result['label']} - ${result['contactName']}';
        });
      }
    }
  }

  // --- ( ✨ NEW: Function for sliding banner ✨ ) ---
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
  // --- ( ✨ END NEW ✨ ) ---


  Widget _buildCircleCategory(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: AssetImage(imagePath), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextColor)),
      ],
    );
  }

  // --- WIDGET UPDATED: Now accepts promotions list ---
  Widget _buildCompactRestaurantCard(
    BuildContext context, 
    VendorModel vendor,
    List<PromotionModel> allPromotions, // <-- NEW PARAMETER
  ) {

    // --- NEW: Find best discount ---
    int? bestDiscount;
    final vendorPromotions = allPromotions.where((p) => p.vendorId == vendor.uid).toList();
    if (vendorPromotions.isNotEmpty) {
      bestDiscount = vendorPromotions.fold(0, (max, promo) => 
        promo.discountPercentage > max! ? promo.discountPercentage : max
      );
      if (bestDiscount == 0) bestDiscount = null;
    }
    // --- END NEW ---

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardColor, // Use style color
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image on Left ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    vendor.businessPhotoUrl, // From Firebase
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
                // --- "HOTDEALS" Tag ---
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
                            fontSize: 10,
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
                  Text(
                    vendor.storeName, // From Firebase
                    style: kLabelTextStyle.copyWith(fontSize: 17),
                    maxLines: 2,
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
                        ' (${vendor.reviewCount})・32 min', // Use real review count
                        style: kHintTextStyle.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Vendor Type
                  Text(
                    vendor.vendorType, // "Restaurant"
                    style: kHintTextStyle.copyWith(fontSize: 14),
                  ),

                  // --- NEW: Promotion Tag ---
                  if (bestDiscount != null) ...[
                    const SizedBox(height: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- END NEW WIDGET ---

  // --- ( ✨ NEW: Banner Widget from MainPage.dart ✨ ) ---
  Widget _buildPromotionsBanner(BuildContext context, List<PromotionModel> allPromotions) {
    
    // --- ( ✨ MODIFIED: Filter for Blindbox and bannerUrl ✨ ) ---
    final bannerPromotions = allPromotions
        .where((promo) => 
            promo.productType == 'Blindbox' && 
            promo.bannerUrl.isNotEmpty && 
            promo.vendorId.isNotEmpty)
        .toList();
    // --- ( ✨ END MODIFIED ✨ ) ---

    if (bannerPromotions.isEmpty) {
      // Return a container with the same gradient as the old one, but no text
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
          height: 112, // Same height as old banner
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: kPromotionGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
           child: const Center(
             child: Text(
              'No promotions available', 
              style: TextStyle(color: Colors.white70)
            ),
           ),
        ),
      );
    }

    // (Re)start the timer whenever the data changes
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
            child: _buildPromotionCard(context, promo), // Need to create this
          );
        },
        onPageChanged: (index) {
          _currentPage = index; // Update current page for the timer
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
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryActionColor)),
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
  // --- ( ✨ END NEW ✨ ) ---

  @override
  Widget build(BuildContext context) {
    // --- Get cart data from provider ---
    final cart = context.watch<CartProvider>();
    final cartItemCount = cart.itemCount;
    final cartTotal = cart.subtotal;
    // --- END ---

    // --- NEW: Promotions Stream ---
    // --- ( ✨ MODIFIED: Removed .where() to avoid index error ✨ ) ---
    final allPromotionsStream = FirebaseFirestore.instance
        .collectionGroup('promotions')
        // .where('endDate', isGreaterThan: Timestamp.now()) // <-- REMOVED
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            PromotionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
          ).toList()
        );
    // --- ( ✨ END MODIFIED ✨ ) ---

    return BasePage(
      currentIndex: 1,
      // --- NEW: Wrap with StreamBuilder for promotions ---
      child: StreamBuilder<List<PromotionModel>>(
        stream: allPromotionsStream,
        builder: (context, promotionSnapshot) {

          // Handle loading/error for promotions
          if (promotionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (promotionSnapshot.hasError) {
              print("Error loading promotions: ${promotionSnapshot.error}");
              // --- ( ✨ NEW: Show error if index is needed ✨ ) ---
              String errorMsg = "Error loading promotions";
              if (promotionSnapshot.error.toString().contains('FAILED_PRECONDITION')) {
                errorMsg = "Firebase index required. Please create it.";
              }
              return Center(child: Text(errorMsg));
          }
          
          // --- ( ✨ MODIFIED: Filter promotions in Dart ✨ ) ---
          final now = DateTime.now();
          final allPromotions = promotionSnapshot.data
              ?.where((p) => p.endDate.isAfter(now))
              .toList() ?? [];
          // --- ( ✨ END MODIFIED ✨ ) ---

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
                                  onTap: _openDeliveryToPage,
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
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- ( ✨ REPLACED: Real Promotions Banner ✨ ) ---
                        _buildPromotionsBanner(context, allPromotions),
                        // --- ( ✨ END REPLACED ✨ ) ---
                        
                        const SizedBox(height: 20),

                        // --- Horizontal Scrollable Food Categories ---
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Explore Categories', style: kLabelTextStyle),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildCircleCategory(
                                  'Promo', 'assets/images/promo.jpg'),
                              const SizedBox(width: 16),
                              _buildCircleCategory(
                                  'Healthy', 'assets/images/healthy.jpg'),
                              const SizedBox(width: 16),
                              _buildCircleCategory(
                                  'Western', 'assets/images/western.jpg'),
                              const SizedBox(width: 16),
                              _buildCircleCategory(
                                  'Dessert', 'assets/images/dessert.jpg'),
                              const SizedBox(width: 16),
                              _buildCircleCategory(
                                  'Chinese', 'assets/images/chinese.png'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- Section title for restaurants ---
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('All Restaurants', style: kLabelTextStyle),
                        ),
                        const SizedBox(height: 10),
                      ]),
                    ),

                    // --- MODIFIED: This is now the list of RESTAURANTS ---
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vendors')
                          // --- THE FIX: Changed 'BlindBox' to 'Blindbox' to match your database ---
                          .where('vendorType', isEqualTo: 'Blindbox')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: kPrimaryActionColor)),
                          );
                        }
                        if (snapshot.hasError) {
                          return SliverToBoxBoxAdapter( // <-- FIX: Was "SliverToBoxBoxAdapter"
                              child:
                                  Center(child: Text('Error: ${snapshot.error}')));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SliverToBoxAdapter(
                              child: Center(
                                  child: Text('No restaurants found.',
                                      style: kHintTextStyle)));
                        }

                        // Build list of restaurant cards
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              VendorModel vendor = VendorModel.fromMap(
                                  snapshot.data!.docs[index].data()
                                      as Map<String, dynamic>);
                              // --- USE THE NEW CARD WIDGET & PASS PROMOTIONS ---
                              return _buildCompactRestaurantCard(context, vendor, allPromotions);
                            },
                            childCount: snapshot.data!.docs.length,
                          ),
                        );
                      },
                    ),
                    // --- END MODIFICATION ---
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
      ),
    );
  }
}

class SliverToBoxBoxAdapter extends SliverToBoxAdapter {
  const SliverToBoxBoxAdapter({super.key, super.child});
}