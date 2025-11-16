import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import '../users/store_detail_page.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'filter_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/cart_page.dart';
import 'dart:async'; 
import 'package:foodiebox/models/promotion.dart';



class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _currentAddress = "Select Location";
  
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMapPage() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPage()),
    );

    if (selectedLocation != null && selectedLocation is Map<String, dynamic>) {
      setState(() {
        _currentAddress = selectedLocation['address'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // --- ( ✨ CORRECTED QUERY: Use CollectionGroup ✨ ) ---
    // This query now looks inside all 'vendors' subcollections for 'promotions'
    final allPromotionsStream = FirebaseFirestore.instance
        .collectionGroup('promotions') // <-- This is the main fix
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            PromotionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
          ).toList()
        );
    // --- ( ✨ END CORRECTED QUERY ✨ ) ---

    return BasePage(
      currentIndex: 0,
      // --- ( ✨ NEW: Wrap with StreamBuilder for promotions ✨ ) ---
      child: StreamBuilder<List<PromotionModel>>(
        stream: allPromotionsStream,
        builder: (context, promotionSnapshot) {
          
          // Handle loading/error for promotions
          if (promotionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (promotionSnapshot.hasError) {
             // --- This will now show the NEW index error ---
             print("Error loading promotions: ${promotionSnapshot.error}");
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    const Text("Error Loading Promotions", style: kLabelTextStyle),
                    const SizedBox(height: 10),
                    Text(
                     "This is normal!\n\nThis new query requires a Firebase Index.\n\nPlease go to the link printed in your 'Run' or 'Debug Console' log to create it.", 
                     style: kHintTextStyle,
                     textAlign: TextAlign.center,
                   ),
                   ],
                 ),
               )
             );
          }

          // This is the list of all active promotions
          final allPromotions = promotionSnapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Top Bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _navigateToMapPage,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: kTextColor),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 150,
                              child: Text(
                                _currentAddress,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(Icons.notifications_none, color: kTextColor),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Badge(
                          label: Text(cart.itemCount.toString()),
                          isLabelVisible: cart.itemCount > 0,
                          child: const Icon(Icons.shopping_cart_outlined,
                              color: kTextColor),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CartPage()),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfilePage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: kPrimaryActionColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.person_outline, color: kTextColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Search Bar ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for shops & products',
                            hintStyle: kHintTextStyle,
                            prefixIcon: const Icon(Icons.search),
                            fillColor: kCardColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.filter_list,
                            color: kPrimaryActionColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FilterPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --- ( ✨ MODIFIED: Pass promotions list to banner ✨ ) ---
                // This already shows Blindbox AND Grocery promotions
                _buildPromotionsBanner(context, allPromotions),
                // --- ( ✨ END MODIFIED ✨ ) ---

                // --- Horizontal Scrollable Categories ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SizedBox(
                    height: 120, // increased from 100 to allow label space
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCircleCategory(
                            'Hot Deals', 'assets/images/hot_deals.jpg'),
                        const SizedBox(width: 16),
                        _buildCircleCategory(
                            'Frozen Rescue', 'assets/images/frozen_rescue.jpg'),
                        const SizedBox(width: 16),
                        _buildCircleCategory(
                            'Pantry Saver', 'assets/images/pantry_saver.jpg'),
                        const SizedBox(width: 16),
                        _buildCircleCategory('Healthy Leftovers',
                            'assets/images/healthy_leftovers.jpg'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // --- ( ✨ MODIFIED: Pass promotions list to vendor list ✨ ) ---
                _buildVendorListSection(
                  title: 'Order snacks from',
                  stream: FirebaseFirestore.instance
                      .collection('vendors')
                      .where('vendorType', isEqualTo: 'Blindbox')
                      .snapshots(),
                  allPromotions: allPromotions, // <-- Pass the list
                ),
                // --- ( ✨ END MODIFIED ✨ ) ---
                
                // --- ( ✨ "SYOK DEALS" SECTION REMOVED ✨ ) ---

                // --- ( ✨ NEW SECTION ADDED ✨ ) ---
                const SizedBox(height: 30),
                _buildVendorListSection(
                  title: 'Order from Grocery',
                  stream: FirebaseFirestore.instance
                      .collection('vendors')
                      .where('vendorType', isEqualTo: 'Grocery')
                      .snapshots(),
                  allPromotions: allPromotions, // <-- Pass the list
                ),
                // --- ( ✨ END NEW SECTION ✨ ) ---

              ],
            ),
          );
        }
      ),
      // --- ( ✨ END NEW: StreamBuilder ✨ ) ---
    );
  }

  // --- ( ✨ MODIFIED: Accepts list, no StreamBuilder ✨ ) ---
  Widget _buildPromotionsBanner(BuildContext context, List<PromotionModel> allPromotions) {
    
    // Filter for promotions that should be in the banner
    final bannerPromotions = allPromotions
        .where((promo) => promo.bannerUrl.isNotEmpty && promo.vendorId.isNotEmpty)
        .toList();

    if (bannerPromotions.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no promotions
    }

    // (Re)start the timer whenever the data changes
    _startAutoSlide(bannerPromotions.length);

    return Container(
      height: 150, // Height for the banner
      margin: const EdgeInsets.only(top: 10), // Added top margin
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerPromotions.length,
        itemBuilder: (context, index) {
          final promo = bannerPromotions[index];
          // Use padding to create space between cards
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildPromotionCard(context, promo),
          );
        },
        onPageChanged: (index) {
          _currentPage = index; // Update current page for the timer
        },
      ),
    );
  }

  // --- ( ✨ UPDATED WIDGET: Uses PromotionModel ✨ ) ---
  Widget _buildPromotionCard(BuildContext context, PromotionModel promo) {
    return GestureDetector(
      onTap: () async {
        // When tapped, fetch the vendor and navigate to the store page
        try {
          // Since the promo.vendorId is correct, we can use it
          final doc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(promo.vendorId) // <-- Use vendorId from the promotion
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
          promo.bannerUrl, // <-- Use bannerUrl from the promotion
          fit: BoxFit.cover,
          width: double.infinity,
          // Loading and error builders for a better user experience
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
  // --- ( ✨ END UPDATED WIDGETS ✨ ) ---


  Widget _buildCircleCategory(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextColor)),
      ],
    );
  }

  // --- ( ✨ MODIFIED: Accepts allPromotions list ✨ ) ---
  Widget _buildVendorListSection({
    required String title, 
    required Stream<QuerySnapshot> stream,
    required List<PromotionModel> allPromotions, // <-- New parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(title, style: kLabelTextStyle),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: kPrimaryActionColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No shops found.', style: kHintTextStyle));
            }

            // --- ( ✨ FULL CODE FIX: REMOVED FILTER ✨ ) ---
            // This now shows ALL vendors from the stream, not just
            // vendors with promotions.
            
            // Build a list of shop cards
            return Column(
              children: snapshot.data!.docs.map((doc) {
                VendorModel vendor =
                    VendorModel.fromMap(doc.data() as Map<String, dynamic>);
                
                // --- ( ✨ MODIFIED: Pass promotions list to card ✨ ) ---
                // _buildShopCard will handle showing the promo tag if one exists
                return _buildShopCard(context, vendor, allPromotions);
                // --- ( ✨ END MODIFIED ✨ ) ---

              }).toList(),
            );
            // --- ( ✨ END FULL CODE FIX ✨ ) ---
          },
        ),
      ],
    );
  }

  // --- ( ✨ MODIFIED: Accepts list, no StreamBuilder ✨ ) ---
  Widget _buildShopCard(BuildContext context, VendorModel vendor, List<PromotionModel> allPromotions) {
    
    // --- ( ✨ NEW: Find best discount synchronously ✨ ) ---
    int? bestDiscount;
    // Find promotions for this specific vendor
    // This works because your vendor.uid is the vendorId
    final vendorPromotions = allPromotions.where((p) => p.vendorId == vendor.uid).toList();
    
    if (vendorPromotions.isNotEmpty) {
      // Find the highest discount percentage
      bestDiscount = vendorPromotions.fold(0, (max, promo) => 
        promo.discountPercentage > max! ? promo.discountPercentage : max
      );
      if (bestDiscount == 0) {
        bestDiscount = null; // Don't show "0% OFF"
      }
    }
    // --- ( ✨ END NEW ✨ ) ---

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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Restaurant Image ---
            // --- ( ✨ REMOVED StreamBuilder ✨ ) ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.network(
                    vendor.businessPhotoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.store,
                            size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
                
                // --- "HOT DEAL" Tag ---
                // This tag is for 'hasExpiryDeals'
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
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
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

                // --- ( ✨ MODIFIED DISCOUNT TAG ✨ ) ---
                // This tag is for 'promotions' (e.g. 50% OFF)
                if (bestDiscount != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: const BoxDecoration(
                        color: kPrimaryActionColor, // Theme color!
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '$bestDiscount% OFF',
                        style: const TextStyle(
                            color: kTextColor, // Theme text color
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // --- ( ✨ END MODIFIED TAG ✨ ) ---
              ],
            ),
            // --- ( ✨ END MODIFICATION ✨ ) ---

            // --- Restaurant Info ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name
                    Text(
                      vendor.storeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Address / subtitle
                    Text(
                      vendor.storeAddress.isNotEmpty
                          ? vendor.storeAddress
                          : 'Free delivery available',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating + Delivery Info Row
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          // --- ( ✨ ERROR FIXED ✨ ) ---
                          vendor.rating.toStringAsFixed(1), // <-- Was toStringAsFieldFixed
                          // --- ( ✨ END FIX ✨ ) ---
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${vendor.reviewCount})', // Shows review count
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.delivery_dining,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          '30-40 min',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
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
}