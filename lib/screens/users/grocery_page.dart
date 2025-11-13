import 'package:flutter/material.dart';
import '../../widgets/base_page.dart';
import 'store_detail_page.dart'; // Adjust path if needed

class GroceryPage extends StatelessWidget {
  const GroceryPage({super.key});

  final List<Map<String, dynamic>> stores = const [
    {
      'name': 'Jaya Grocer – DC Mall',
      'location': 'Damansara, KL',
      'image': 'assets/images/jaya_dc.jpg',
      'rating': 4.7,
      'distance': '6.2 km',
      'category': 'Supermarket',
      'expiryTag': true,
    },
    {
      'name': 'Village Grocer – Bangsar',
      'location': 'Bangsar South',
      'image': 'assets/images/village_bangsar.jpg',
      'rating': 4.6,
      'distance': '4.8 km',
      'category': 'Organic',
      'expiryTag': true,
    },
    {
      'name': 'Lotus’s – Cheras',
      'location': 'Cheras',
      'image': 'assets/images/lotus_cheras.jpg',
      'rating': 4.5,
      'distance': '7.1 km',
      'category': 'Halal',
      'expiryTag': true,
    },
    {
      'name': 'Econsave – Kuchai Lama',
      'location': 'Kuchai Lama',
      'image': 'assets/images/econsave_kuchai.jpg',
      'rating': 4.3,
      'distance': '3.5 km',
      'category': 'Budget',
      'expiryTag': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 2, // Grocery tab index
      child: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // --- Top Section ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Grocery Stores Near You',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stores or categories',
                        prefixIcon: const Icon(Icons.search),
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add filter logic
                    },
                    icon: const Icon(Icons.filter_alt_outlined, size: 20),
                    label: const Text('Expiry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Store Cards ---
            ...stores.map((store) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreDetailPage(store: store),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(2, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.asset(
                          store['image'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Store Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store['name'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(store['location'],
                                style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 18),
                                Text('${store['rating']}'),
                                const SizedBox(width: 12),
                                Text(store['category']),
                                const Spacer(),
                                const Icon(Icons.location_on,
                                    size: 18, color: Colors.grey),
                                Text(store['distance'],
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            if (store['expiryTag']) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Near-expiry deals available',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500),
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
            }).toList(),
          ],
        ),
      ),
    );
  }
}
