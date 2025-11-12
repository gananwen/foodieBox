import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
// --- (NEW) 导入模型和仓库 ---
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

// --- Product Page (Figure 27) ---
class ProductPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const ProductPage({super.key, required this.onBackToDashboard});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- (NEW) ---
  final ProductRepository _productRepo = ProductRepository();

  // This set tracks which product IDs are currently selected
  final Set<String> _selectedProductIds = {};

  // --- (REMOVED) 虚拟数据和 _loadDummyProducts() 已删除 ---

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  // --- (MODIFIED) Deletes all selected products from Firebase ---
  Future<void> _deleteSelectedProducts() async {
    // (你可以在这里添加一个 loading 状态)
    try {
      // 为每个选中的 ID 并行触发删除
      final deleteFutures =
          _selectedProductIds.map((id) => _productRepo.deleteProduct(id));
      await Future.wait(deleteFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_selectedProductIds.length} Products deleted')),
        );
      }

      setState(() {
        _selectedProductIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete products: $e')),
        );
      }
    }
  }

  // --- (MODIFIED) Builds the list from the Firebase data ---
  Widget _buildProductList(List<Product> allProducts, String filterType) {
    List<Product> filteredList;

    if (filterType == 'All') {
      filteredList = allProducts;
    } else {
      // 使用我们模型中的 'productType' 字段
      filteredList =
          allProducts.where((p) => p.productType == filterType).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'No products in this category.',
          style: TextStyle(color: kTextColor.withOpacity(0.7), fontSize: 16),
        ),
      );
    }

    // Use ListView.builder for performance
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Padding for FAB
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final bool isSelected = _selectedProductIds.contains(product.id!);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            // 1. Checkbox on the left
            leading: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                _toggleSelection(product.id!);
              },
              activeColor: kPrimaryActionColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),

            // 2. --- (MODIFIED) Image placeholder (loads real image) ---
            trailing: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: kAppBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              // 如果 imageUrl 为空，显示图标，否则加载网络图片
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.image_outlined,
                      color: kTextColor, size: 35)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        // 可选：添加加载和错误占位符
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error_outline,
                              color: kPrimaryActionColor, size: 35);
                        },
                      ),
                    ),
            ),

            // 3. --- (MODIFIED) Product Type (from model) ---
            title: Text(
              product.productType,
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),

            // 4. --- (MODIFIED) Product Name and Price (from model) ---
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title, // 使用 'title'
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // (你可以按需添加 'sold' 字段)
                Text(
                  'RM${product.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // 5. Tap to Edit
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
      return const SizedBox.shrink();
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
          onPressed: widget.onBackToDashboard,
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
                          _deleteSelectedProducts(); // 调用 async 函数
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
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
      // --- (MODIFIED) Body now uses a StreamBuilder ---
      body: Column(
        children: [
          _buildSelectionHeader(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productRepo.getProductsStream(),
              builder: (context, snapshot) {
                // 1. Handle Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryActionColor));
                }
                // 2. Handle Error
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: kTextColor)));
                }
                // 3. Handle No Data
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No products found. Tap "+" to add one!',
                          style: TextStyle(color: kTextColor, fontSize: 16)));
                }

                // 4. Handle Success
                final allProducts = snapshot.data!;

                // 将获取到的数据传递给 TabBarView
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductList(allProducts, 'All'),
                    _buildProductList(allProducts, 'Blind Box'),
                    _buildProductList(allProducts, 'Grocery Deal'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button for Add Product
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
