import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
// --- 1. 导入模型和仓库 ---
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';
import 'dart:math' as math; // 用于计算

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
  final PromotionRepository _promoRepo = PromotionRepository();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Products deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete products: $e')),
      );
    }
  }

  Widget _buildSelectionHeader() {
    if (_selectedProductIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: kSecondaryAccentColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedProductIds.length} Selected',
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kPrimaryActionColor),
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
      ),
    );
  }

  // --- (已修改) _buildProductList ---
  // 它现在接收两个列表：产品和促销
  Widget _buildProductList(
      List<Product> allProducts, List<PromotionModel> activePromos) {
    // 1. 创建一个 Map 来快速查找促销
    // e.g., {'Blindbox': 20, 'Grocery': 0}
    final promoMap = <String, int>{};
    for (var promo in activePromos) {
      promoMap[promo.productType] = promo.discountPercentage;
    }

    // 2. 按标签页过滤
    final String currentTabType;
    switch (_tabController.index) {
      case 1:
        currentTabType = 'Blindbox';
        break;
      case 2:
        currentTabType = 'Grocery';
        break;
      default:
        currentTabType = 'All';
    }

    final filteredList = (currentTabType == 'All')
        ? allProducts
        : allProducts.where((p) => p.productType == currentTabType).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'No products in this category.',
          style: TextStyle(color: kTextColor),
        ),
      );
    }

    // 3. 构建列表
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final bool isSelected = _selectedProductIds.contains(product.id!);
        // --- (已修改) 获取此产品的折扣 ---
        final int discount = promoMap[product.productType] ?? 0;

        return _ProductCard(
          product: product,
          discountPercentage: discount, // 传递折扣
          isSelected: isSelected,
          onTap: () {
            // --- (已修改) 导航到 EditProductPage ---
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProductPage(
                  product: product,
                  discountPercentage: discount, // 传递折扣
                ),
              ),
            );
          },
          onSelect: () {
            _toggleSelection(product.id!);
          },
        );
      },
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
            Container() // 占位符, 因为删除按钮已移到 _buildSelectionHeader
          else
            IconButton(
              icon: const Icon(Icons.add, color: kTextColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
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
            Tab(text: 'Blind Boxes'),
            Tab(text: 'Grocery deals'),
          ],
          onTap: (index) {
            // 切换标签页时清除选择
            setState(() {
              _selectedProductIds.clear();
            });
          },
        ),
      ),
      // --- (已修改) 使用嵌套的 StreamBuilder ---
      body: Column(
        children: [
          _buildSelectionHeader(),
          Expanded(
            // 1. StreamBuilder 1: 获取促销
            child: StreamBuilder<List<PromotionModel>>(
              stream: _promoRepo.getPromotionsStream(),
              builder: (context, promoSnapshot) {
                if (promoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryActionColor));
                }
                // (我们不关心促销错误或空状态，没有促销=0%折扣)
                final activePromos = promoSnapshot.data ?? [];

                // 2. StreamBuilder 2: 获取产品
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
                          child: Text('Error: ${productSnapshot.error}'));
                    }
                    if (!productSnapshot.hasData ||
                        productSnapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No products found. Add one!'));
                    }

                    final allProducts = productSnapshot.data!;

                    // 3. 返回 TabBarView
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductList(allProducts, activePromos),
                        _buildProductList(allProducts, activePromos),
                        _buildProductList(allProducts, activePromos),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- (已修改) 全新 "Modern" 产品卡片 UI ---
class _ProductCard extends StatelessWidget {
  final Product product;
  final int discountPercentage;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _ProductCard({
    required this.product,
    required this.discountPercentage,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? kPrimaryActionColor : kTextColor.withOpacity(0.1),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: kTextColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // 1. Checkbox
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: isSelected,
                onChanged: (val) => onSelect(),
                activeColor: kPrimaryActionColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            // 2. Image
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kAppBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.image_outlined,
                      color: kTextColor, size: 35)
                  : null,
            ),
            // 3. Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- (新增) 类别标签 ---
                    if (product.category.isNotEmpty)
                      _CategoryChip(category: product.category),
                    // ---
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
                    Text(
                      'Stock: ${product.quantity}',
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PriceInfo(
                      originalPrice: product.discountedPrice,
                      discountPercentage: discountPercentage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (辅助) 价格 Widget
class _PriceInfo extends StatelessWidget {
  final double originalPrice;
  final int discountPercentage;

  const _PriceInfo(
      {required this.originalPrice, required this.discountPercentage});

  @override
  Widget build(BuildContext context) {
    if (discountPercentage == 0) {
      return Text(
        'RM${originalPrice.toStringAsFixed(2)}',
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }

    final double discountedPrice =
        originalPrice * (1 - (discountPercentage / 100));

    return Row(
      children: [
        Text(
          'RM${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            color: kPrimaryActionColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'RM${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: kTextColor.withOpacity(0.5),
            fontWeight: FontWeight.normal,
            fontSize: 13,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}

// (辅助) 类别标签
class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kSecondaryAccentColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
