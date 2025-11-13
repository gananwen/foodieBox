import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';

// --- 1. 导入新模型和仓库 ---
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';

class ProductPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  const ProductPage({super.key, required this.onBackToDashboard});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductRepository _productRepo = ProductRepository();
  final PromotionRepository _promotionRepo = PromotionRepository();
  final Set<String> _selectedProductIds = {};

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

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  Future<void> _deleteSelectedProducts() async {
    try {
      final deleteFutures =
          _selectedProductIds.map((id) => _productRepo.deleteProduct(id));
      await Future.wait(deleteFutures);

      setState(() {
        _selectedProductIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete products: $e')),
        );
      }
    }
  }

  Map<String, int> _processPromotions(List<PromotionModel> promos) {
    Map<String, int> promoMap = {};
    for (var promo in promos) {
      final type = promo.productType;
      if (!promoMap.containsKey(type) ||
          promo.discountPercentage > promoMap[type]!) {
        promoMap[type] = promo.discountPercentage;
      }
    }
    return promoMap;
  }

  Widget _buildProductList(
    List<Product> allProducts,
    String filterType,
    Map<String, int> promotionsMap,
  ) {
    List<Product> filteredList;
    if (filterType == 'All') {
      filteredList = allProducts;
    } else {
      filteredList =
          allProducts.where((p) => p.productType == filterType).toList();
    }

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'No products in this category.',
          style: TextStyle(color: kTextColor),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final bool isSelected = _selectedProductIds.contains(product.id!);
        final int discount = promotionsMap[product.productType] ?? 0;

        return _ProductCard(
          product: product,
          isSelected: isSelected,
          discountPercentage: discount,
          onTap: () {
            // 如果处于选择模式，点击卡片 = 选择
            if (_selectedProductIds.isNotEmpty) {
              _toggleSelection(product.id!);
            } else {
              // 否则 = 导航到编辑
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(
                    product: product,
                    // --- ( ✨ 关键修改 ✨ ) ---
                    // 1. 将折扣传递给详情页
                    discountPercentage: discount,
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            _toggleSelection(product.id!);
          },
        );
      },
    );
  }

  Widget _buildSelectionHeader() {
    if (_selectedProductIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: kPrimaryActionColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${_selectedProductIds.length} Selected',
        style: const TextStyle(
          color: kPrimaryActionColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('My Products', style: TextStyle(color: kTextColor)),
        backgroundColor: kAppBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: widget.onBackToDashboard,
        ),
        actions: [
          if (_selectedProductIds.isNotEmpty)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: kPrimaryActionColor),
              onPressed: () {
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
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kTextColor,
          labelColor: kTextColor,
          unselectedLabelColor: kTextColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Blindbox'),
            Tab(text: 'Grocery'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSelectionHeader(),
          Expanded(
            child: StreamBuilder<List<PromotionModel>>(
              stream: _promotionRepo.getPromotionsStream(),
              builder: (context, promoSnapshot) {
                if (promoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryActionColor));
                }
                if (promoSnapshot.hasError) {
                  return Center(
                      child: Text(
                          'Error loading promotions: ${promoSnapshot.error}'));
                }

                final promotions = promoSnapshot.data ?? [];
                final promotionsMap = _processPromotions(promotions);

                return StreamBuilder<List<Product>>(
                  stream: _productRepo.getProductsStream(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: kPrimaryActionColor));
                    }
                    if (productSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'Error loading products: ${productSnapshot.error}'));
                    }
                    if (!productSnapshot.hasData ||
                        productSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No products found. Tap "+" to create one.',
                          style: TextStyle(color: kTextColor),
                        ),
                      );
                    }

                    final allProducts = productSnapshot.data!;
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductList(allProducts, 'All', promotionsMap),
                        _buildProductList(
                            allProducts, 'Blindbox', promotionsMap),
                        _buildProductList(
                            allProducts, 'Grocery', promotionsMap),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductPage(),
            ),
          );
        },
        backgroundColor: kSecondaryAccentColor,
        foregroundColor: kTextColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- (产品卡片) ---
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final int discountPercentage;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.discountPercentage,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = discountPercentage > 0;
    final double discountedPrice =
        product.discountedPrice * (1 - discountPercentage / 100);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? kPrimaryActionColor : kTextColor.withOpacity(0.1),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: kPrimaryActionColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      ),
                      color: kAppBackgroundColor,
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Center(
                            child: Icon(Icons.image_outlined,
                                color: kTextColor, size: 40))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (hasDiscount) ...[
                        Text(
                          'RM${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kPrimaryActionColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'RM${product.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: kTextColor.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'RM${product.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasDiscount)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryActionColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$discountPercentage% OFF',
                    style: const TextStyle(
                      color: kCardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: kPrimaryActionColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: kCardColor, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
