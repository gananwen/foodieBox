import 'package:flutter/material.dart';
import '../../util/styles.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../models/promotion.dart';
import '../../repositories/promotion_repository.dart';
// --- ( ✨ 新增导入 ✨ ) ---
import '../../repositories/vendor_data_repository.dart';
// --- ( ✨ 结束 ✨ ) ---
import 'dart:math' as math;

class ProductPage extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  // --- ( ✨ 关键修改 ✨ ) ---
  final VendorDataBundle bundle; // 接收 bundle
  const ProductPage({
    super.key,
    required this.onBackToDashboard,
    required this.bundle, // 添加到 constructor
  });
  // --- ( ✨ 结束修改 ✨ ) ---

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductRepository _productRepo = ProductRepository();
  final PromotionRepository _promoRepo = PromotionRepository();
  final Set<String> _selectedProductIds = {};

  // --- ( ✨ 新增变量 ✨ ) ---
  late String _vendorType;
  // --- ( ✨ 结束 ✨ ) ---

  @override
  void initState() {
    super.initState();
    // --- ( ✨ 关键修复：代码顺序 ✨ ) ---
    // 1. 必须 *先* 初始化 _vendorType
    _vendorType = widget.bundle.vendor.vendorType;

    // 2. *然后* 再使用 _vendorType 来初始化 _tabController
    if (_vendorType == 'Blindbox') {
      _tabController = TabController(length: 1, vsync: this);
    } else {
      // 'Grocery' 供应商现在只有 2 个 tabs
      _tabController = TabController(length: 2, vsync: this);
    }
    // --- ( ✨ 结束修复 ✨ ) ---
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ... (_toggleSelection, _deleteSelectedProducts, _buildSelectionHeader 保持不变) ...
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

  // --- ( ✨ 已修改：_buildProductList ✨ ) ---
  Widget _buildProductList(
      List<Product> allProducts, List<PromotionModel> activePromos) {
    final promoMap = <String, int>{};
    for (var promo in activePromos) {
      promoMap[promo.productType] = promo.discountPercentage;
    }

    // ( ✨ 逻辑简化：'allProducts' 已经是过滤后的 ✨ )
    // 'allProducts' 已经被 repository 按 vendorType 过滤了
    // 'Grocery' 供应商的 'All' tab 会显示所有 'Grocery' 产品
    List<Product> filteredList = allProducts;

    // 只有当 'Grocery' 供应商点击 'Grocery' 标签页时，我们才需要再次过滤
    // (这个逻辑是假设 'Grocery' 供应商可能也会创建 'Blindbox'，
    // 但根据我们的新 repository, 他们不能, 所以这个过滤是安全的)
    if (_vendorType == 'Grocery' && _tabController.index == 1) {
      // 这是 'Grocery' 供应商的 "Grocery deals" 标签
      filteredList =
          allProducts.where((p) => p.productType == 'Grocery').toList();
    } else if (_vendorType == 'Grocery' && _tabController.index == 0) {
      // "All" 标签页
      filteredList = allProducts;
    }

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
      // ... (ListView.builder 内部不变) ...
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final bool isSelected = _selectedProductIds.contains(product.id!);
        final int discount = promoMap[product.productType] ?? 0;

        return _ProductCard(
          product: product,
          discountPercentage: discount,
          isSelected: isSelected,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProductPage(
                  product: product,
                  discountPercentage: discount,
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

  // --- ( ✨ 已修改：build ✨ ) ---
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
            Container()
          else
            IconButton(
              icon: const Icon(Icons.add, color: kTextColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(
                      vendorType: _vendorType,
                    ),
                  ),
                );
              },
            ),
        ],
        // --- ( ✨ 关键修改：动态 Tabs ✨ ) ---
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kTextColor,
          labelColor: kTextColor,
          unselectedLabelColor: kTextColor.withOpacity(0.6),
          // 2. 根据 vendorType 显示不同的 Tabs
          tabs: _vendorType == 'Blindbox'
              ? const [
                  Tab(text: 'My Blind Boxes'), // 只有一个 Tab
                ]
              : const [
                  Tab(text: 'All'), // 'Grocery' 供应商的 "All"
                  Tab(text: 'Grocery deals'), // 'Grocery' 供应商的 "Grocery"
                ],
          onTap: (index) {
            setState(() {
              _selectedProductIds.clear();
            });
          },
        ),
        // --- ( ✨ 结束修改 ✨ ) ---
      ),
      body: Column(
        children: [
          _buildSelectionHeader(),
          Expanded(
            child: StreamBuilder<List<PromotionModel>>(
              stream: _promoRepo.getPromotionsStream(),
              builder: (context, promoSnapshot) {
                if (promoSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryActionColor));
                }
                final activePromos = promoSnapshot.data ?? [];

                return StreamBuilder<List<Product>>(
                  // --- ( ✨ 关键修改 ✨ ) ---
                  // 3. 将 vendorType 传递给 repository
                  stream: _productRepo.getProductsStream(_vendorType),
                  // --- ( ✨ 结束修改 ✨ ) ---
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

                    return TabBarView(
                      controller: _tabController,
                      // --- ( ✨ 关键修改 ✨ ) ---
                      // 4. 确保 TabBarView 匹配 Tab 列表
                      children: _vendorType == 'Blindbox'
                          ? [
                              _buildProductList(allProducts, activePromos),
                            ]
                          : [
                              _buildProductList(allProducts, activePromos),
                              _buildProductList(allProducts, activePromos),
                            ],
                      // --- ( ✨ 结束修改 ✨ ) ---
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

// --- ( ✨ _ProductCard (已修复拼写错误) ✨ ) ---
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: isSelected,
                onChanged: (val) => onSelect(),
                activeColor: kPrimaryActionColor,
                // --- ( ✨ 关键修复：拼写错误 ✨ ) ---
                shape: RoundedRectangleBorder(
                    // <-- 之前是 Gorder
                    borderRadius: BorderRadius.circular(4)),
                // --- ( ✨ 结束修复 ✨ ) ---
              ),
            ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.category.isNotEmpty)
                      _CategoryChip(category: product.category),
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

// --- (_PriceInfo, _CategoryChip 保持不变) ---
// (代码已折叠)
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
