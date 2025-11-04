import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'filter_page.dart';
import 'main_page.dart';

// Changed to StatefulWidget for robustness and future use
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final List<String> deliveryTags = const [
    'W Hotel buffet',
    'egg',
    'Bread',
    'Verona Hills',
    'Fresh Milk',
    'Lavender',
    'Jogoya Starhill',
    'Empire Sushi',
    'Kampung Kitchen @ Ibis KLCC',
  ];

  final List<Map<String, dynamic>> categories = const [
    {'label': 'Bakery', 'icon': Icons.bakery_dining},
    {'label': 'Buffet', 'icon': Icons.restaurant_menu},
    {'label': 'Salads', 'icon': Icons.local_dining},
    {'label': 'Desserts', 'icon': Icons.icecream},
    {'label': 'Meat', 'icon': Icons.set_meal},
    {'label': 'Asian', 'icon': Icons.rice_bowl},
  ];

  // Helper function to build a cleaner Category Item
  Widget _buildCategoryItem(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: kPrimaryActionColor),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextColor)),
          ],
        ),
      ),
    );
  }

  // Helper function to build a cleaner Chip
  Widget _buildDeliveryTagChip(String tag) {
    return Chip(
      label: Text(tag, style: const TextStyle(fontSize: 12, color: kTextColor)),
      backgroundColor: kYellowSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          },
        ),
        title: const Text('Find Store', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Search Bar with Filter Icon ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for shops and products',
                        hintStyle: kHintTextStyle,
                        prefixIcon: const Icon(Icons.search),
                        fillColor: kCardColor,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: kYellowMedium, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: kYellowMedium, width: 1.5),
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
              const SizedBox(height: 20),

              // --- Popular Searches / Delivery Tags ---
              const Text('Popular Searches', style: kLabelTextStyle),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: deliveryTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return _buildDeliveryTagChip(deliveryTags[index]);
                  },
                ),
              ),
              const SizedBox(height: 30),

              // --- Browse by Category ---
              const Text('Browse by Category', style: kLabelTextStyle),
              const SizedBox(height: 10),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: categories.map((item) {
                    return _buildCategoryItem(item['label'], item['icon']);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
