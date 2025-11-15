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
import '../users/map_page.dart';

// --- IMPORT REMOVED ---

class BlindBox extends StatefulWidget {
  const BlindBox({super.key});

  @override
  State<BlindBox> createState() => _BlindBoxState();
}

class _BlindBoxState extends State<BlindBox> {
  String? selectedAddressName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
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

  // --- WIDGET REPLACED: This now matches your screenshot ---
  Widget _buildCompactRestaurantCard(BuildContext context, VendorModel vendor) {
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
                        ' (500+)・RM 1.20・32 min', // Placeholder text
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

                  // --- Promotion Tag ---
                  if (vendor.hasExpiryDeals) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RM7.00 discount', // Placeholder text
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

  @override
  Widget build(BuildContext context) {
    // --- Get cart data from provider ---
    final cart = context.watch<CartProvider>();
    final cartItemCount = cart.itemCount;
    final cartTotal = cart.subtotal;
    // --- END ---

    return BasePage(
      currentIndex: 1,
      child: Stack(
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

                    // --- Promotions Banner ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: kPromotionGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.image,
                                  size: 40, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Promotions',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  SizedBox(height: 6),
                                  Text(
                                      'Check out the latest vouchers available!',
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // --- TEMPORARY BUTTON REMOVED ---

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
                      return SliverToBoxAdapter(
                          // <-- FIX: Was "SliverToBoxBoxAdapter"
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
                          // --- USE THE NEW CARD WIDGET ---
                          return _buildCompactRestaurantCard(context, vendor);
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
      ),
    );
  }
}