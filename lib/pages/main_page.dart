// lib/pages/main_page.dart
import 'package:flutter/material.dart';
import '../../../../utils/styles.dart'; // keep your path to styles.dart
import 'map_page.dart';
import 'food_page.dart';
import 'grocery_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Keep the original map logic
  String _currentAddress = "Select Location";

  // Keep your existing map navigation logic unchanged
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
    return Scaffold(
      backgroundColor: kCardColor, // clean white background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- 1. Top Bar & Location (Tappable) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
              child: Row(
                children: [
                  // LOCATION AREA - tap to open map
                  GestureDetector(
                    onTap: _navigateToMapPage,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: kTextColor),
                        const SizedBox(width: 4),
                        // Constrain the width so long text is truncated
                        SizedBox(
                          width:
                              150, // adjust based on your layout (try 120–180)
                          child: Text(
                            _currentAddress,
                            overflow: TextOverflow.ellipsis, // adds "..."
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

            // --- 2. Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for shops & products',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: kSecondaryAccentColor, // pale yellow
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

            // --- 3. Main Categories ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryItem('Blindbox', Icons.archive, context),
                  _buildCategoryItem('Food', Icons.lunch_dining, context),
                  _buildCategoryItem('Grocery', Icons.shopping_bag, context),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- 4. Promotions Banner ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kPrimaryActionColor, // pink
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check out the latest vouchers!',
                    style: TextStyle(color: Color.fromARGB(179, 255, 255, 255)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- 5. "Order snacks from" Header ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Order snacks from', style: kLabelTextStyle),
              ),
            ),
            const SizedBox(height: 10),

            // --- 6. Restaurant Info Placeholder ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 150,
              decoration: BoxDecoration(
                color: kSecondaryAccentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Restaurant info (Filtered by user location)',
                  style: TextStyle(color: kTextColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Category item UI builder (with navigation logic)
  Widget _buildCategoryItem(String label, IconData icon, BuildContext context) {
    Widget? targetPage;
    if (label == 'Food') {
      targetPage = const FoodPage();
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
