import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import 'map_page.dart';
import 'blind_box.dart';
import 'grocery_page.dart';
import 'filter_page.dart';

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

    // Correctly handles the returned Map<String, dynamic>
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Top Bar & Location ---
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
                          borderSide: const BorderSide(
                              color: kYellowMedium, width: 1.5), // Using kYellowMedium
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: kYellowMedium, width: 1.5), // Using kYellowMedium
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.filter_list,
                        color: kPrimaryActionColor), // Using kPrimaryActionColor
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

            // --- Sliding Promo Banner ---
            SizedBox(
              height: 160,
              child: PageView.builder(
                itemCount: 3,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      // **THEME CHANGE:** Using kPromotionGradient (Pink/Red)
                      gradient: kPromotionGradient, 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Syok Deals: RM10 OFF',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 6),
                        Text('Limited time offers from top-rated shops!',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // --- Categories ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildCategoryItem('Promo', Icons.local_offer),
                  _buildCategoryItem('Healthy', Icons.eco),
                  _buildCategoryItem('Pizza', Icons.local_pizza),
                  _buildCategoryItem('Ramen', Icons.ramen_dining),
                  _buildCategoryItem('Burger', Icons.fastfood),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Order Snacks Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Order snacks from', style: kLabelTextStyle),
            ),
            const SizedBox(height: 10),
            _buildShopCard('W Hotel Buffet',
                'PSD Free delivery WKL Klang (spend RM30)', 4.9),
            _buildShopCard(
                'Tesco', 'PSD Free delivery WKL Klang (spend RM30)', 4.8),
            const SizedBox(height: 30),

            // --- Syok Deals Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Syok Deals: RM10 OFF', style: kLabelTextStyle),
            ),
            const SizedBox(height: 10),
            _buildShopCard('W Hotel Buffet', 'Limited time RM10 OFF', 4.9),
            _buildShopCard('Tesco', 'Limited time RM10 OFF', 4.8),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: kYellowLight, // Using kYellowLight
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, color: kTextColor, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextColor)),
      ],
    );
  }

  Widget _buildShopCard(String title, String subtitle, double rating) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kYellowLight, // Using kYellowLight
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
              color: kCardColor, // Using kCardColor (White)
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
              Text(rating.toString(), style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}