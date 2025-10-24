import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import '../../widgets/base_page.dart';
import 'map_page.dart';
import 'blind_box.dart';
import 'grocery_page.dart';
import 'profile_page.dart';
import 'browse_page.dart';
import 'order_page.dart';

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

    if (selectedLocation != null) {
      setState(() {
        _currentAddress = selectedLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 0, // Home tab index
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
                  icon: const Icon(Icons.notifications_none, color: kTextColor),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for shops & products',
                prefixIcon: const Icon(Icons.search),
                fillColor: kCardColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // --- Categories ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem('Food', Icons.archive),
                _buildCategoryItem('Grocery', Icons.shopping_bag),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- Promotions ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: kPromotionGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promotions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('Check out the latest vouchers!',
                    style:
                        TextStyle(color: Color.fromARGB(179, 255, 255, 255))),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- Restaurant Info ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Order snacks from', style: kLabelTextStyle),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 150,
            decoration: BoxDecoration(
              color: kSecondaryAccentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('Restaurant info (Filtered by user location)',
                  style: TextStyle(color: kTextColor)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    Widget? targetPage;
    if (label == 'Food') {
      targetPage = const BlindBox();
    } else if (label == 'Grocery') {
      targetPage = const GroceryPage();
    }

    return GestureDetector(
      onTap: () {
        if (targetPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage!),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: kSecondaryAccentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kTextColor, size: 30),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: kTextColor)),
        ],
      ),
    );
  }
}
