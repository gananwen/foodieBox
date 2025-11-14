import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import '../users/store_detail_page.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'filter_page.dart';
import '../../api/api_config.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/cart_page.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _currentAddress = "Select Location";

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
    // --- NEW: Get the cart provider to watch for changes ---
    final cart = context.watch<CartProvider>();

    return BasePage(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Top Bar (MODIFIED) ---
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
                  // --- MODIFIED CART ICON ---
                  IconButton(
                    icon: Badge(
                      // Show the number of items in the cart
                      label: Text(cart.itemCount.toString()),
                      // Only show the badge if the cart is not empty
                      isLabelVisible: cart.itemCount > 0,
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: kTextColor),
                    ),
                    onPressed: () {
                      // Navigate to the new CartPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartPage()),
                      );
                    },
                  ),
                  // --- END MODIFIED CART ICON ---
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

            // --- Search Bar (No Changes) ---
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

            // --- Horizontal Scrollable Categories (No Changes) ---
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

            // --- Promotions Banner (No Changes) ---
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
                      child:
                          const Icon(Icons.image, size: 40, color: Colors.grey),
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
                          Text('Check out the latest vouchers available!',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- "Order snacks from" Section ---
            _buildVendorListSection(
              title: 'Order snacks from',
              stream:
                  FirebaseFirestore.instance.collection('vendors').snapshots(),
            ),
            const SizedBox(height: 30),

            // --- "Syok Deals" Section ---
            _buildVendorListSection(
              title: 'Syok Deals: RM10 OFF',
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .orderBy('rating', descending: true)
                  .limit(5)
                  .snapshots(),
            ),
          ],
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

  // --- Reusable Vendor List Widget ---
  Widget _buildVendorListSection(
      {required String title, required Stream<QuerySnapshot> stream}) {
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

            // Build a list of shop cards
            return Column(
              children: snapshot.data!.docs.map((doc) {
                VendorModel vendor =
                    VendorModel.fromMap(doc.data() as Map<String, dynamic>);
                // --- MODIFIED ---
                // Pass context to the card builder
                return _buildShopCard(context, vendor);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- MODIFIED: This is YOUR UI, now made tappable ---
  Widget _buildShopCard(BuildContext context, VendorModel vendor) {
    // --- WRAPPED IN GESTUREDETECTOR ---
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Open the new StoreDetailPage and pass the vendor data
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
            // --- Restaurant Image (Your 100x100 UI) ---
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
                    child:
                        const Icon(Icons.store, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),

            // --- Restaurant Info (Your UI) ---
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