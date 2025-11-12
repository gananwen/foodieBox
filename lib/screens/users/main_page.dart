import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import 'map_page.dart';
import '../users/profile_page.dart';
import 'filter_page.dart';
import '../../api/api_config.dart';


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
    return BasePage(
      currentIndex: 0,
      child: SingleChildScrollView(
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
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: kTextColor),
                    onPressed: () {},
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
                      child:
                          const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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

            // --- Order Snacks Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Order snacks from', style: kLabelTextStyle),
            ),
            const SizedBox(height: 10),
            _buildShopCard('W Hotel Buffet',
                'PSD Free delivery WKL Klang (spend RM30)', 4.9, 504),
            _buildShopCard(
                'Tesco', 'PSD Free delivery WKL Klang (spend RM30)', 4.8, 3080),
            const SizedBox(height: 30),

            // --- Syok Deals Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Syok Deals: RM10 OFF', style: kLabelTextStyle),
            ),
            const SizedBox(height: 10),
            _buildShopCard('W Hotel Buffet', 'Limited time RM10 OFF', 4.9, 504),
            _buildShopCard('Tesco', 'Limited time RM10 OFF', 4.8, 3080),
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
            boxShadow: [
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

  Widget _buildShopCard(
      String title, String subtitle, double rating, int reviews) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 30, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: kHintTextStyle),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 20),
              Text('$rating', style: const TextStyle(fontSize: 14)),
              Text('$reviews+', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
