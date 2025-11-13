import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/util/styles.dart';
import '../../widgets/base_page.dart';
import 'store_detail_page.dart'; 

class GroceryPage extends StatelessWidget {
  const GroceryPage({super.key});


  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 2, // Grocery tab index
      child: Column(
        children: [
          const SizedBox(height: 50), // Added padding for the top
          // --- Top Section (No changes) ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Grocery Stores Near You',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
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
                      hintStyle: kHintTextStyle,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: kCardColor, // Use style color
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
                        horizontal: 12, vertical: 12), // Adjusted padding
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Store Cards from Firebase ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .where('vendorType', isEqualTo: 'Grocery')
                  .snapshots(),
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
                      child: Text('No grocery stores found.',
                          style: kHintTextStyle));
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: snapshot.data!.docs.map((doc) {
                    VendorModel vendor =
                        VendorModel.fromMap(doc.data() as Map<String, dynamic>);
                    
                    // Use your new card UI
                    return _buildStoreCard(context, vendor);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED WIDGET: This card now has the BIG BANNER IMAGE at the top ---
  Widget _buildStoreCard(BuildContext context, VendorModel vendor) {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // The padding is removed from here
        decoration: BoxDecoration(
          color: kCardColor, // Use style color
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Store Banner Image ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                vendor.businessPhotoUrl, // From Firebase
                height: 180, // This makes the image big
                width: double.infinity,
                fit: BoxFit.cover, // This will cover the area
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, size: 60, color: Colors.grey),
                  );
                },
              ),
            ),
            
            // --- Store Info (All left-aligned) ---
            Padding(
              padding: const EdgeInsets.all(16), // Add padding back here
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.storeName, // From Firebase
                    style: kLabelTextStyle.copyWith(fontSize: 18)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor.storeAddress, // From Firebase
                    style: kHintTextStyle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        vendor.rating.toStringAsFixed(1),
                        style: kLabelTextStyle.copyWith(fontSize: 14),
                      ), // From Firebase
                      const SizedBox(width: 12),
                      Text(
                        vendor.vendorType, // From Firebase
                        style: kHintTextStyle.copyWith(fontSize: 14),
                      ), 
                      const Spacer(),
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('5.0 km', style: kHintTextStyle), // Placeholder for distance
                    ],
                  ),
            
                  // --- Expiry Deals Tag ---
                  if (vendor.hasExpiryDeals) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  }
}