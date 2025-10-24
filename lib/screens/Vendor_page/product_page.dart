import 'package:flutter/material.dart';
import '../../utils/styles.dart'; // Using your team's styles
import 'add_product_page.dart';
import 'edit_product_page.dart';

// --- Product Page (Figure 27) ---
class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // This list holds all products, as if from Firebase
  List<Product> _allProducts = [];

  // This set tracks which product IDs are currently selected
  final Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load dummy data when the page starts
    _loadDummyProducts();
  }

  void _loadDummyProducts() {
    // This is where you would fetch data from Firebase Firestore
    setState(() {
      _allProducts = [
        Product(
            id: 'p1',
            name: 'Mystery Box',
            type: 'Blind Box',
            price: 20.00,
            sold: '100+ sold',
            imageUrl: ''),
        Product(
            id: 'p2',
            name: 'Fresh Apples',
            type: 'Grocery Deal',
            price: 20.00,
            sold: '100+ sold',
            imageUrl: ''),
        Product(
            id: 'p3',
            name: 'Fresh Orange',
            type: 'Grocery Deal',
            price: 20.00,
            sold: '100+ sold',
            imageUrl: ''),
        Product(
            id: 'p4',
            name: 'Fresh Mango',
            type: 'Grocery Deal',
            price: 20.00,
            sold: '100+ sold',
            imageUrl: ''),
        Product(
            id: 'p5',
            name: 'Fresh Corn',
            type: 'Grocery Deal',
            price: 20.00,
            sold: '100+ sold',
            imageUrl: ''),
      ];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Toggles the selection of a product
  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  // Deletes all selected products
  void _deleteSelectedProducts() {
    // This is where you would send delete requests to Firebase
    setState(() {
      _allProducts.removeWhere((p) => _selectedProductIds.contains(p.id));
      _selectedProductIds.clear();
    });
    // Show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Products deleted')),
    );
  }

  // Builds the list of products based on the selected tab
  Widget _buildProductList(String filterType) {
    List<Product> filteredList;

    if (filterType == 'All') {
      filteredList = _allProducts;
    } else {
      filteredList = _allProducts.where((p) => p.type == filterType).toList();
    }

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'No products in this category.',
          style: TextStyle(color: kTextColor),
        ),
      );
    }

    // Use ListView.builder for performance
    return ListView.builder(
      // Add padding to the list itself
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Padding for FAB
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final bool isSelected = _selectedProductIds.contains(product.id);

        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6), // Increased vertical margin
          decoration: BoxDecoration(
            color: kCardColor, // White
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? kPrimaryActionColor
                  : kTextColor.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 8.0), // Increased vertical padding
            // 1. Checkbox on the left
            leading: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                // This now ONLY controls the checkbox
                _toggleSelection(product.id);
              },
              activeColor: kPrimaryActionColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),

            // 2. Image placeholder on the right
            trailing: Container(
              width: 70, // Increased size
              height: 70, // Increased size
              decoration: BoxDecoration(
                color: kAppBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_outlined,
                  color: kTextColor, size: 35), // Increased size
            ),

            // 3. Product Type
            title: Text(
              product.type,
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),

            // 4. Product Name and Price
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      product.sold,
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RM${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 5. This tap is for the whole tile area *except* the checkbox
            onTap: () {
              // This is for Figure 29
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(product: product),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // This builds the "X Selected" bar (matches Figure 27)
  Widget _buildSelectionHeader() {
    if (_selectedProductIds.isEmpty) {
      return const SizedBox
          .shrink(); // Return an empty box if nothing is selected
    }
    return Container(
      color: kSecondaryAccentColor.withOpacity(0.5), // Light green
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${_selectedProductIds.length} Selected',
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor, // FEFFE1
      appBar: AppBar(
        title: const Text('My Products', style: TextStyle(color: kTextColor)),
        backgroundColor: kAppBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Show Delete button ONLY if items are selected
          if (_selectedProductIds.isNotEmpty)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: kPrimaryActionColor),
              onPressed: () {
                // Show a confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: Text(
                        'Are you sure you want to delete ${_selectedProductIds.length} product(s)?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: kPrimaryActionColor),
                        child: const Text('Delete'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _deleteSelectedProducts();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          // --- REMOVED: Add button IconButton was here ---
        ],
        // The TabBar for filtering
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kTextColor,
          labelColor: kTextColor,
          unselectedLabelColor: kTextColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Blind Boxes'),
            Tab(text: 'Grocery deals'),
          ],
        ),
      ),
      body: Column(
        children: [
          // This displays the "X Selected" bar
          _buildSelectionHeader(),
          // This displays the list of products
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductList('All'),
                _buildProductList('Blind Box'),
                _buildProductList('Grocery Deal'),
              ],
            ),
          ),
        ],
      ),
      // --- ADDED: Floating Action Button for Add Product ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductPage(),
            ),
          );
        },
        backgroundColor: kSecondaryAccentColor, // Light Green
        foregroundColor: kTextColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Data Model ---
// A simple class to represent a Product.
// In a real app, this would have fromJson/toJson methods for Firebase.
class Product {
  final String id;
  final String name;
  final String type; // 'Blind Box' or 'Grocery Deal'
  final double price;
  final String sold;
  final String imageUrl; // Placeholder for product image

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.sold,
    required this.imageUrl,
  });
}
