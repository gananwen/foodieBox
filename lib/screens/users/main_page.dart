import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import '../users/store_detail_page.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/cart_page.dart';
import 'dart:async'; 
import 'package:foodiebox/models/promotion.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../users/status_notification_bar.dart'; 
import '../../repositories/notification_repository.dart'; 
import '../shared/notifications_page.dart'; 
import '../users/subpages/delivery_address_page.dart'; 


class MainPage extends StatefulWidget {
  final String? pendingOrderId; 
  const MainPage({super.key, this.pendingOrderId});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _currentAddress = "Select Location";
  
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  
  final NotificationRepository _notificationRepo = NotificationRepository(); 

  // --- NEW SEARCH STATE ---
  final TextEditingController _searchController = TextEditingController();
  List<VendorModel> _searchResults = [];
  Timer? _debounce;
  // --- END NEW SEARCH STATE ---


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _loadSelectedAddress();
    
    // --- NEW: Listen to search bar changes ---
    _searchController.addListener(_onSearchChanged);
    // --- END NEW ---
  }
  
  Future<void> _loadSelectedAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['selectedAddress'] != null) {
      final addr = data['selectedAddress'];
      setState(() =>
          _currentAddress = addr['address'] ?? 'Select Location');
    }
  }
  
  // --- NEW: Debounced search function ---
  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      // CRITICAL FIX: Only call setState if the results list is actually changing
      if (_searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
      }
      return;
    }
    
    // Debounce the call to avoid hitting Firestore too hard
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchVendors(text);
    });
  }

  Future<void> _searchVendors(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('storeName', isGreaterThanOrEqualTo: query)
          .where('storeName', isLessThan: query + '\uf7ff') // Unicode upper bound for prefix search
          .limit(5) // Limit results for performance
          .get();

      // Only rebuild if the search results have actually changed
      final newResults = snapshot.docs
          .map((doc) => VendorModel.fromMap(doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = newResults;
        });
      }
    } catch (e) {
      print("Error searching vendors: $e");
      if (mounted) {
        setState(() => _searchResults = []);
      }
    }
  }
  
  void _selectVendor(VendorModel vendor) {
    // Navigate to the store detail page for the selected vendor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailPage(vendor: vendor),
      ),
    );
    // Clear search state after selection/navigation
    _searchController.clear();
    setState(() => _searchResults = []);
  }
  // --- END NEW SEARCH FUNCTIONS ---


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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- MODIFIED: Navigate directly to address selection page ---
  Future<void> _navigateToAddressSelection() async {
    // Navigate to the DeliveryAddressPage, which returns the selected address data
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryAddressPage()),
    );

    if (selectedLocation != null && selectedLocation is Map<String, dynamic>) {
      // 1. Update the user's default selected address in Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'selectedAddress': selectedLocation,
          });
      }
      
      // 2. Update the local state
      setState(() {
        _currentAddress = selectedLocation['address'] as String;
      });
    }
  }
  
  void _navigateToNotificationsPage(BuildContext context) {
    // FIX: Ensure correct path and remove const if arguments are dynamic
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(userRole: 'User'),
      ),
    );
  }

  // --- NEW HELPER WIDGET: Contains Search Bar and Dropdown (Now placed outside main build stack) ---
  Widget _buildSearchBarWithDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          
          // --- Autocomplete Dropdown Overlay (Embedded in Column, appears below) ---
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final vendor = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.storefront, color: kPrimaryActionColor),
                        title: Text(
                          vendor.storeName, 
                          style: kLabelTextStyle.copyWith(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(vendor.vendorType, style: kHintTextStyle),
                        onTap: () => _selectVendor(vendor),
                      );
                    },
                  ),
                ),
              ),
            ),
          // --- END Autocomplete Dropdown Overlay ---
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currentUser = FirebaseAuth.instance.currentUser; // Get current user

    final allPromotionsStream = FirebaseFirestore.instance
        .collectionGroup('promotions') 
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            PromotionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
          ).toList()
        );

    Widget buildMainContent(List<PromotionModel> allPromotions) {
        return Stack(
          children: [
            // --- FIX 2: Corrected GestureDetector to use the named 'child' argument ---
            GestureDetector(
              onTap: () {
                // Clear focus to hide keyboard and remove search results
                FocusScope.of(context).unfocus();
                if (_searchResults.isNotEmpty) {
                  setState(() => _searchResults = []);
                }
              },
              child: SingleChildScrollView( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top Bar (Remains same) ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _navigateToAddressSelection,
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
                          if (currentUser != null)
                            StreamBuilder<int>(
                              stream: _notificationRepo.getUnreadNotificationCountStream(),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                return IconButton(
                                  icon: Badge(
                                    label: Text(unreadCount.toString()),
                                    isLabelVisible: unreadCount > 0,
                                    child: const Icon(Icons.notifications_none, color: kTextColor),
                                  ),
                                  onPressed: () => _navigateToNotificationsPage(context),
                                );
                              }
                            )
                          else 
                            IconButton(
                                icon: const Icon(Icons.notifications_none, color: kTextColor),
                                onPressed: () => _navigateToNotificationsPage(context),
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

                    // --- Search Bar and Dropdown (Now self-contained helper) ---
                    _buildSearchBarWithDropdown(context),
                    // --- End Search Bar ---
                    
                    _buildPromotionsBanner(context, allPromotions),

                    // --- Horizontal Scrollable Categories (Remaining content remains the same) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // REDUCED VERTICAL PADDING
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
                    
                    // --- LAYOUT FIX: Reduced vertical space here ---
                    const SizedBox(height: 10), 
                    // --- END LAYOUT FIX ---

                    _buildVendorListSection(
                      title: 'Order snacks from',
                      stream: FirebaseFirestore.instance
                          .collection('vendors')
                          .where('vendorType', isEqualTo: 'Blindbox')
                          .snapshots(),
                      allPromotions: allPromotions, 
                    ),
                    
                    const SizedBox(height: 30),
                    _buildVendorListSection(
                      title: 'Order from Grocery',
                      stream: FirebaseFirestore.instance
                          .collection('vendors')
                          .where('vendorType', isEqualTo: 'Grocery')
                          .snapshots(),
                      allPromotions: allPromotions, 
                    ),
                    
                    const SizedBox(height: 100), // Extra space for cart bubble offset
                  ],
                ),
              ),
            ),
            
            // --- Floating Cart Bubble (Remains the same) ---
            Positioned(
              right: 20,
              bottom: 12,
              child: AnimatedOpacity(
                opacity: cart.itemCount > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: cart.itemCount > 0
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
                            label: Text('RM ${cart.subtotal.toStringAsFixed(2)}',
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
                              child: Text('${cart.itemCount}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            // --- END Floating Cart ---
          ],
        );
    }


    // 2. StreamBuilder around the main content
    Widget content = StreamBuilder<List<PromotionModel>>(
        stream: allPromotionsStream,
        builder: (context, promotionSnapshot) {
          
          if (promotionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (promotionSnapshot.hasError) {
             print("Error loading promotions: ${promotionSnapshot.error}");
             // Return simplified error handling for brevity
             return const Center(child: Text("Error loading promotions."));
          }

          final allPromotions = promotionSnapshot.data ?? [];
          return buildMainContent(allPromotions);
        }
      );

    // 3. Wrap in BasePage and conditionally wrap in OrderStatusChecker
    Widget mainPageScaffold = BasePage(
      currentIndex: 0,
      child: content,
    );
    
    if (widget.pendingOrderId != null) {
      // FIX: Use OrderStatusChecker widget correctly
      return OrderStatusChecker(
        orderId: widget.pendingOrderId!,
        child: mainPageScaffold,
      );
    }
    
    return mainPageScaffold;
  }
  
  // --- START OF HELPER METHODS ---

  Widget _buildPromotionsBanner(BuildContext context, List<PromotionModel> allPromotions) {
    
    final bannerPromotions = allPromotions
        .where((promo) => promo.bannerUrl.isNotEmpty && promo.vendorId.isNotEmpty)
        .toList();

    if (bannerPromotions.isEmpty) {
      return const SizedBox.shrink(); 
    }

    _startAutoSlide(bannerPromotions.length);

    return Container(
      height: 150, 
      margin: const EdgeInsets.only(top: 10), 
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerPromotions.length,
        itemBuilder: (context, index) {
          final promo = bannerPromotions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildPromotionCard(context, promo),
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
            // NOTE: Assuming VendorModel.fromMap exists
            final vendor = doc.data() != null ? VendorModel.fromMap(doc.data() as Map<String, dynamic>) : null; 
            if (vendor != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDetailPage(vendor: vendor),
                ),
              );
            }
          }
        } catch (e) {
          print("Error navigating to vendor: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load store.')),
          );
        }
      },
      // --- FIX: Added Container wrapper for the border ---
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.0), // Light border
        ),
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
      ),
    );
  }

  Widget _buildCircleCategory(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              // Assuming AssetImage paths are correct
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

  Widget _buildVendorListSection({
    required String title, 
    required Stream<QuerySnapshot> stream,
    required List<PromotionModel> allPromotions, 
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
            
            return Column(
              children: snapshot.data!.docs.map((doc) {
                VendorModel vendor =
                    VendorModel.fromMap(doc.data() as Map<String, dynamic>);
                
                return _buildShopCard(context, vendor, allPromotions);

              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShopCard(BuildContext context, VendorModel vendor, List<PromotionModel> allPromotions) {
    
    int? bestDiscount;
    // NOTE: Assuming vendor.uid exists for filtering
    final vendorPromotions = allPromotions.where((p) => p.vendorId == (vendor.uid ?? '')).toList(); 
    
    if (vendorPromotions.isNotEmpty) {
      bestDiscount = vendorPromotions.fold(0, (max, promo) => 
        promo.discountPercentage > max! ? promo.discountPercentage : max
      );
      if (bestDiscount == 0) {
        bestDiscount = null;
      }
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
                if (vendor.hasExpiryDeals)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: const BoxDecoration(
                        // Changed from dark red to a sharp, visible color
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
              ],
            ),
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
                          vendor.rating.toStringAsFixed(1),
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
                    
                    // --- VISUAL FIX: Discount Tag PLACED HERE (Bellow ratings) ---
                    if (bestDiscount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          // --- MODIFIED TO GREEN VOUCHER STYLE ---
                          decoration: BoxDecoration(
                            color: Colors.green.shade100, 
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$bestDiscount% OFF',
                            style: TextStyle(
                              color: Colors.green.shade800, 
                              fontWeight: FontWeight.w500, // Use w500 to match voucher body text
                              fontSize: 12,
                            ),
                          ),
                          // --- END MODIFIED ---
                        ),
                      ),
                    // --- END VISUAL FIX ---
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