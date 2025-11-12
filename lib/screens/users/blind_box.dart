import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import '../users/delivery_to_page.dart';
import '../users/map_page.dart';

class BlindBox extends StatefulWidget {
  const BlindBox({super.key});

  @override
  State<BlindBox> createState() => _BlindBoxState();
}

class _BlindBoxState extends State<BlindBox> {
  String? selectedAddressName;
  int cartItemCount = 2;
  double cartTotal = 24.90;
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

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 1,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    children: [
                      _buildCircleCategory('Promo', 'assets/images/promo.jpg'),
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

                const Center(
                  child: Text(
                    'Coming soon...',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // --- Floating Cart Bubble ---
          Positioned(
            right: 20,
            bottom: 12,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                FloatingActionButton.extended(
                  backgroundColor: Colors.amber,
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: Text('RM ${cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white)),
                ),
                if (cartItemCount > 0)
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
            ),
          ),
        ],
      ),
    );
  }
}
